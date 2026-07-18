# Architecture

> Status: draft — decided by Wannes Gennar, 2026-07-08; amended 2026-07-18
> (gateway validates Axis A tokens via JWKS and owns no data — a consequence
> of the [identity.md](identity.md) amendments of that date); amended
> 2026-07-19 (the gateway does **not** depend on `meshum`; the gateway → web
> transport is `UNDECIDED`, BEAM clustering rejected for it). Items marked
> `UNDECIDED` are open; do not assume an answer for them.

Meshum is composed of three components (the fourth item below is a shared
library, not a deployable component).

## Components

### `daemon/` — the client daemon (Rust)

A Rust binary that runs on **employee machines**, with a tray icon for status
and similar local UX. Its job is to **synchronise settings and decisions from
the control plane** (`meshum_web`, see below) onto the local machine.

What the daemon can sync:

- agents, skills, configs;
- agent settings (think `~/.claude/settings.json`, or updating organisation
  settings) and hooks;
- long term, even AI-related tooling like `rtk` on `PATH`.

The daemon does **not** enforce/block anything locally. Meshum is here to help
*govern*, not to block things (though a company can deploy hooks that block).
Rationale: a dedicated developer can work around blocks most of the time
anyway.

How the daemon actually realises a `Manifest` item on the machine — the
closed-vocabulary operation model it is constrained to, and how it reports its
own health back — is [daemon-reconciliation.md](daemon-reconciliation.md).

### `server/apps/meshum_gateway` — the MCP proxy (Elixir/Phoenix)

An **MCP proxy** running on the server. AI agents call the gateway **as if it
were the MCP server they need** (Jira, GitHub, …).

**The gateway is a single aggregated MCP server, not one virtual server per
upstream.** A harness makes exactly one MCP connection and one OAuth
handshake with the gateway; the gateway internally holds every configured
`UpstreamServer` and merges their tools into its own tool list, namespaced
`<upstream>.<tool_name>` (e.g. `jira.get_issue`, `github.get_issue`) so
identically-named tools on different upstreams never collide. The namespace
prefix doubles as the routing key: it tells the gateway which
`UpstreamServer`/credential to use when dispatching the call. When an admin
adds an upstream in the control plane, the gateway extends its aggregated
tool list and can push MCP's `notifications/tools/list_changed` to already-
connected clients — no client reconfiguration, no new OAuth handshake, no
new connection. This was chosen over one-server-per-upstream specifically
because the latter has no standard mechanism for a client to auto-discover
and auto-connect to a newly-added upstream — MCP has nothing analogous to a
server push for "here's a new server you should also connect to," so it
would need either manual client reconfiguration per upstream or harness-side
auto-discovery behavior Meshum doesn't control.

**The gateway is a thin interception seam — it holds no policy semantics of
its own.** Its only job on the decision path is to
extract the inputs from an incoming MCP call — the caller's `user_ref`, the
target `upstream`, and the `tool_name` — and hand them off to `meshum_web` for
the actual allow/block decision (evaluated by `meshum`'s logic, which lives
behind `meshum_web` — the gateway does not link `meshum` itself). It consults
that decision per call at
`tools/call` (blocking a disallowed call) and uses it to filter the
aggregated list at `tools/list`; the evaluation **fails closed**. No
evaluation or rule-interpretation logic lives in the `meshum_gateway` app
itself — that is `meshum`'s (see below). See
[governance.md](governance.md#tool-access-granularity) for what those rules
are (`ToolAccess`).

Consistently, **the gateway owns no data.** It validates a caller's Axis A
token statelessly against `meshum_web`'s published JWKS (no read of the
authorization server's storage, no per-call introspection hop), and its only
two contact surfaces are that JWKS endpoint and an authenticated network call
to `meshum_web` for policy and `UpstreamConnection` resolution (transport
`UNDECIDED` — see [identity.md](identity.md#gateway--control-plane-trust)).
**The gateway does not depend on `meshum` as a library or OTP application** —
that logic lives behind `meshum_web`. This keeps it
decoupled from the AS implementation and separable from the umbrella later.

### `server/apps/meshum_web` — the control plane (Elixir/Phoenix LiveView)

The web interface / **control plane**. This is where organisations see, manage
and deploy their policies, hooks, and so forth. Those changes get synced out to
the gateway (server side) and the daemon (client side).

### `server/apps/meshum` — shared business logic (Elixir)

The home of **all schema and all evaluation/decision logic — not in the
callers.** `meshum_web` depends on it in-process as a library; the gateway
does **not** depend on it (neither at compile time nor as an OTP application
dependency) and reaches its decisions over a network hop to `meshum_web`
instead (see [Communication](#communication) below). Both the gateway and web
app stay thin: they extract inputs and render results, `meshum` decides.
Concretely this includes:

- **runtime tool-access evaluation** (`ToolAccess` — the MCP allow/block rules
  the gateway consults per call, fails closed; see
  [governance.md](governance.md#tool-access-granularity)), and
- **the declarative desired-state `Manifest`** — its schema, the diff against
  current state, and the version-controlled YAML import/apply flow (see
  [control-plane.md](control-plane.md#version-controlled-desired-state-yaml)).

## Communication

- **daemon → web**: the daemon talks to the control plane (`meshum_web`) to
  sync settings/skills/config. This is a **sync** relationship, unrelated to
  MCP or tool calls — see [identity.md](identity.md#axis-b--daemon--control-plane-sync).
  The daemon also acts as a **telemetry fallback**: when a harness can't emit
  OpenTelemetry natively, the daemon (or a hook) forwards it to `meshum_web`
  on the harness's behalf — see [governance.md](governance.md#telemetry).
- **gateway → web**: the gateway talks to the control plane (`meshum_web`).
- **gateway ↮ daemon**: the gateway and daemon do **not** talk to each other.
- **harness → gateway**: AI harnesses (Claude Code, …) call the gateway
  **directly** to make MCP tool calls, authenticating per the MCP spec's
  OAuth 2.1 requirements. **The daemon has no role in this path** — this is
  worth stating explicitly since it is easy to mistakenly assume the daemon
  sits in the tool-call path. See [identity.md](identity.md#axis-a--ai-harness--gateway-the-mcp-tool-call-path)
  for the full flow.
- **harness → web (telemetry)**: when a harness supports OpenTelemetry
  natively (Claude Code), it sends telemetry **directly** to `meshum_web`'s
  ingestion endpoint over **HTTP/JSON** — a custom shim that accepts
  whatever the harness's exporter posts (in practice a standard OTLP/JSON
  export envelope, per [control-plane.md](control-plane.md#observed-event-shapes-spike-findings-2026-07-10--claude-code-only)),
  not a full OTLP collector (no OTLP/gRPC, no protocol negotiation) — not
  through the gateway, not through the daemon. This is a
  third, independent relationship alongside the two auth axes in
  [identity.md](identity.md); the endpoint requires a bearer token but v1
  only checks that one is present — see
  [identity.md](identity.md#telemetry-ingestion-auth).
- Communication method/protocol:
  - **daemon → web is HTTP polling for the MVP** — a **poll** sync model:
    changes propagate on the poll interval. Better/other sync methods (push via
    WebSocket, gRPC, …) can be added later.
  - **gateway → web transport is `UNDECIDED`.** This is a per-call *hot path*
    (policy and `UpstreamConnection` resolution), not a poll, so it is not
    covered by the daemon's polling model. The exact mechanism (HTTP,
    WebSocket, gRPC, …) is deliberately deferred until MCP calls are actually
    being tested. Distributed-Erlang / BEAM clustering between the two was
    considered and **rejected** for this hop — see
    [identity.md](identity.md#gateway--control-plane-trust).

## Deployment model

- Meshum is **self-hosted by organisations**; a **hosted offering** exists for
  companies that want it. Every deployment is single-tenant (no `Org` table);
  the hosted offering provisions an isolated instance per customer rather
  than sharing one multi-tenant database — see [identity.md](identity.md#tenancy).
- The **daemon is always deployed to employee/client computers**.
- **web and gateway** can run on the same machine, in Docker, K8s, ….
