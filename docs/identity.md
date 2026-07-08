# Identity, tenancy & auth

> Status: draft — decided by Wannes Gennar, 2026-07-08. Items marked
> `UNDECIDED` are open; do not assume an answer for them.

This page covers who/what Meshum authenticates, how tenancy works, and — the
part most likely to be misread — **two fully independent auth relationships
that must never be conflated.**

## Tenancy

**No `Org` table.** A Meshum deployment is single-tenant: one deployment = one
organisation. Self-hosted and hosted both work this way — the hosted offering
means provisioning an isolated instance per customer, not a shared
multi-tenant database. There is no `org_id` anywhere in the schema.

## Identity ownership

Meshum does **not** own user or team identity/membership — the customer's
identity provider (IdP) does (Entra, Okta, …). Meshum keeps lightweight
**cached mirror rows** for users and teams, refreshed from IdP claims at
login, existing only so machines, policies, and telemetry have something
stable to point at. Single team per machine/user — no multi-team precedence
rules in v1.

## The two axes

### Axis A — AI harness ↔ gateway (the MCP tool-call path)

An AI harness (Claude Code, and presumably others later) talks **directly**
to `meshum_gateway`. This is pure MCP-spec territory:

1. The harness authenticates to **Meshum's own OAuth/OIDC authorization
   server** and gets a short-lived, refreshable resource-server token for the
   gateway. Meshum's AS federates authentication to the customer's IdP
   (OIDC); the harness self-registers as an OAuth client via **Dynamic Client
   Registration (RFC 7591)** since there's no human available to
   pre-register it.
2. The gateway validates that token per call and checks org/team allow-block
   policy (see [governance.md](governance.md)).
3. If the call targets an upstream tool (Jira, GitHub, …), the gateway
   exchanges (RFC 8693 token exchange) the caller's Meshum token for a
   per-user, upstream-tool-scoped token, using an upstream connection the
   employee set up themselves in advance (see below).
4. The upstream tool sees the actual employee as the actor in its own audit
   log — native permissions and auditing apply. This is deliberate: a shared
   service credential per upstream tool was considered and rejected, because
   it becomes a privilege-escalation vector (a shared credential can do
   anything the most-privileged user can) and breaks upstream tools' native
   authorization/audit trails.

**The daemon has no role anywhere in this axis.**

**Authorization server implementation:** built on
[`boruta`](https://hex.pm/packages/boruta) (`boruta_auth`), which already
ships Dynamic Client Registration support in its core library
(`Boruta.Openid.register_client/3`, tested since v2.3.0) — Meshum adds a thin
`POST /register` HTTP endpoint on top of that existing primitive (the
boruta maintainers' own reference server has one, disabled by default, that
serves as a template) plus `.well-known` discovery advertisement. Rate
limiting/abuse policy on that endpoint is Meshum's own responsibility either
way.

**Upstream connections are self-serve and proactive, not lazy.** An employee
logs into `meshum_web` directly and explicitly connects each upstream
account (Jira, GitHub, …) there — a one-time OAuth consent per tool — before
ever touching an AI harness. There is no admin bulk-provisioning of per-user
upstream identity in v1: each employee connects their own account.

### Axis B — daemon ↔ control plane (sync)

The daemon on an employee's machine polls `meshum_web` to sync
skills/agents/config/policy locally (see
[architecture.md](architecture.md#daemon----the-client-daemon-rust)). This
needs its own, separate credential — entirely unrelated to MCP, OAuth 2.1
resource-server validation, or upstream token exchange.

- **Enrollment is login: a loopback-redirect OAuth flow, `gcloud auth login`
  style.** The daemon binds a local port and opens the employee's browser to
  a Meshum auth URL with that port as the redirect target. The employee
  authenticates (usually a warm IdP session already — near-instant, no
  password prompt), and the browser redirects the credential straight back
  to the daemon's local listener. **That single event is enrollment**: it
  creates the `Machine` and its `MachineCredential` together, tied to the
  authenticating `UserRef`, with no separate code-exchange step. The
  device-authorization-grant pattern (`gh auth login` style — short code +
  URL, works headless) was considered and rejected for v1: every target
  machine is a desktop with the daemon's tray icon present, so the simpler
  loopback flow is sufficient. The machine is auto-named (e.g. hostname) at
  enrollment with no employee input, renameable later. The machine's team is
  resolved transitively through the owning employee (machine → owning user →
  team) — a machine does not carry an independent team assignment.
- **Credential shape:** short-lived access token with refresh
  (client-credentials-style, no human interaction on each poll after
  enrollment). Enrollment issues a long-lived refresh credential once; the
  daemon exchanges it for a short-lived access token every poll cycle.

## Gateway ↔ control plane trust

The gateway process authenticates to `meshum_web`/shared logic to fetch
policy using a **deployment-level shared secret** for v1 (gateway and web run
in the same trust boundary per [architecture.md](architecture.md)). Flagged
to harden later (e.g. per-process credential) — not now.

## Schema sketch

Informational — not binding on implementation, but captures the shape the
above implies (`server/apps/meshum`, per
[`.claude/rules/ecto.md`](../.claude/rules/ecto.md) conventions):

- `TeamRef` — cached IdP team/group.
- `UserRef` — cached IdP user, belongs to a `TeamRef`.
- `Machine` — belongs to an owning `UserRef` (team resolved transitively, no
  separate team field); has a `name` (auto-populated at enrollment,
  renameable) and a rotating `MachineCredential`; created atomically at the
  loopback-redirect enrollment callback, no separate code-exchange entity.
- `Policy` — org-wide or team-scoped allow/block rules.
- `UpstreamServer` — a registered upstream MCP tool (Jira, GitHub, …) and
  Meshum's own OAuth client registration with it.
- `UpstreamConnection` — a specific employee's linked account with an
  `UpstreamServer` (access/refresh tokens, encrypted at rest).

The authorization server's own client/token tables are not sketched here —
they come from `boruta`.

## Login flow implementation

- **OIDC relying-party library:** [`assent`](https://hex.pm/packages/assent)
  — chosen for broad enterprise-IdP coverage (presets plus generic OIDC
  support) without heavy per-customer glue code.
- **Admin roles:** no role distinction in v1 — anyone who can log into the
  control plane can manage policy, skills, and upstream connections for the
  org, and connect their own upstream accounts. This is a **deliberate v1
  simplification, not a permanent stance**: proper authorization controls
  (an admin/viewer distinction or similar) are intended for a later version,
  just not v1/MVP.
