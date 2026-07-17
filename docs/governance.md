# Governance scope (v1)

> Status: draft — decided by Wannes Gennar, 2026-07-08. Items marked
> `UNDECIDED` are open; do not assume an answer for them.

v1 is deliberately an **MVP**: the basic governance defined below and nothing
more.

## Philosophy

Meshum helps organisations *govern* AI usage; it is not in the business of
blocking things. A dedicated developer can work around blocks most of the time
anyway. Organisations that want hard blocks can deploy hooks that block.

## Telemetry

Most AI clients support outputting OpenTelemetry — either out of the box (like
Claude Code) or through plugins (OpenCode). **Primary path: the harness emits
OTel directly to the control plane's ingestion endpoint.** The daemon and/or
hooks are the fallback for harnesses that don't support OTel natively —
forwarding on the harness's behalf, not the default path when native support
exists. The gateway is not part of this signal path; MCP-call visibility
comes from the MCP control pillar above, not from telemetry ingestion.

Telemetry is ingested by the **control plane** (`meshum_web`), over
**HTTP/JSON** — a custom shim, not a full OTLP collector, though harnesses in
practice post standard OTLP/JSON export envelopes (see
[control-plane.md](control-plane.md#observed-event-shapes-spike-findings-2026-07-10--claude-code-only)).
Ingestion might get split out into a separate OTel collector component
later. The
endpoint requires a bearer token; **v1 only validates that a token is
present**, not what it is or who it identifies — see
[identity.md](identity.md#telemetry-ingestion-auth).

**v1 event storage: raw, append-only, CQRS-adjacent.** Store ingested events
essentially as received; do not normalize into a bespoke queryable schema in
v1. Periodic aggregation into read-optimized projections is anticipated for
whenever a real dashboard gets built, but is explicitly **not** v1 work —
v1's UI need (a plain recent-activity list, see
[control-plane.md](control-plane.md#telemetry)) is satisfiable by querying
the raw table directly, ordered by time. See
[control-plane.md](control-plane.md#schema-sketch) for the `TelemetryEvent`
shape this implies.

## MCP control

The initial goal is to **filter MCP servers/tools**: since the gateway proxies
MCP calls (it's just JSON underneath), it can filter out tools that aren't
allowed.

v1 scope: **allowing/blocking servers + tools through the gateway.** Nothing
beyond that on the tool-access side — but note this is enforced *in addition to*,
not instead of, per-user upstream credential exchange, which is also v1
scope: the gateway exchanges the caller's identity for a per-user upstream
token (rather than a shared service credential) before proxying a call, so
that upstream tools' native authorization and audit trails keep working. See
[identity.md](identity.md#axis-a--ai-harness--gateway-the-mcp-tool-call-path)
for the full flow.

**These runtime allow/block rules are `ToolAccess`.** `ToolAccess` is the
**runtime** half of governance: evaluated **per call**, consumed by the
**gateway** at `tools/call` (and to filter `tools/list`), failing **closed** —
a blocked or failed evaluation yields `{:error, :blocked}`, never an implicit
allow. The other half — declarative desired state the daemon reconciles,
never evaluated live — is the `Manifest` (see
[Skill/agent distribution](#skillagent-distribution) below). The
end-user-facing nav reads "Policies" since that's clearer for non-technical
admins (see
[control-plane.md](control-plane.md#tool-access-policies--mcp-allowblock-only)); that's
a UI-copy choice, distinct from the `ToolAccess` concept/schema name.

## Skill/agent distribution

In scope for v1.

- **Source of truth: the control plane.** Organisations author/upload skills
  and agents in `meshum_web`; the server stores them and the daemon syncs them
  down.
- **Installation is harness-dependent.** The daemon has per-harness adapters
  that install via whatever mechanism each supported AI client uses natively.
  v1 ships the **Claude Code adapter only**. These same adapters realise all
  daemon-managed capabilities, not just skills/agents — see
  [daemon-reconciliation.md](daemon-reconciliation.md#capability-routing) for
  how a capability is routed to the daemon versus a harness vendor's own admin
  API, and the closed-vocabulary operation model the adapters are constrained
  to.
- **Scoping: a simple picker** — org-wide or specific team(s), **not** the
  `ToolAccess` override/precedence mechanism (see
  [control-plane.md](control-plane.md#skills--agents)).
- **Managed state:** the daemon re-syncs on drift — a skill removed locally
  gets restored. This is managed state, not blocking; the philosophy above
  still applies.
- **Versioning: latest-only.** The control plane holds one current version per
  skill/agent; daemons converge to it. No pinning or rollback in v1.

**Skills, agents, configs and — long-term — tool installs like `rtk` on
`PATH` are collectively an org's declarative desired state, the `Manifest`.**
It is a *specification*, not a runtime
decision: unlike `ToolAccess` above, nothing evaluates it per call. The daemon
reconciles local machine state against it Kubernetes-controller-style — diff
spec vs. actual, then add/update/remove to converge (the "re-syncs on drift"
behaviour above, restated as one model). The `Manifest` is also the unit of
version-controlled import/export (see below and
[control-plane.md](control-plane.md#version-controlled-desired-state-yaml)).

## Tool-access granularity

v1: `ToolAccess` rules are **org-wide and scoped** — a global baseline with
**team-level overrides**, team winning outright (org policy is a
default/baseline, not a hard ceiling; see
[control-plane.md](control-plane.md#tool-access-policies--mcp-allowblock-only) for
the tree/precedence UI). Skill/agent (`Manifest`) scoping is separate and
simpler — a plain org-wide-or-specific-team(s) picker, no override/precedence
logic.

## Version-controlled desired state

The `Manifest` — the full org's desired state (every
team's skills, agents, config, and tool installs) — is version-controllable as
a single YAML document, GitOps-style. This is a **server-side** mechanism in
`meshum`/`meshum_web`; the full flow (whole-org scope, full-replace import,
plan-then-apply over one `Ecto.Multi`) is specified in
[control-plane.md](control-plane.md#version-controlled-desired-state-yaml). Two
boundaries worth stating in scope terms:

- **`ToolAccess` is deliberately excluded from the YAML mechanism in v1** — the
  runtime allow/block rules stay UI/DB-managed only. Cheap to fold in later,
  but out of v1 scope.
- **This is not the daemon's reconciliation loop.** The YAML mechanism
  converges the *control plane's* stored state to an imported document.
  Converging an *employee machine's* actual state to whatever `Manifest` the
  server holds is the daemon's separate, not-yet-designed job (Rust side) — do
  not assume the server-side import work covers it.

## Explicitly out of scope for v1

Advanced features beyond the basic governance above, including:

- audit logs
- approval flows
- per-user / per-machine overrides
