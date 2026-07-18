# Identity, tenancy & auth

> Status: draft — decided by Wannes Gennar, 2026-07-08; amended 2026-07-18
> (upstream registration is MCP-client discovery + DCR with a manual fallback;
> the gateway validates Axis A JWTs statelessly via JWKS and owns no data;
> bounded credential liveness forces every credential chain back through the
> IdP at least once per bounded window).
> Items marked `UNDECIDED` are open; do not assume an answer for them.

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
login and re-verified against the IdP at least once per bounded window (see
[Bounded credential liveness](#bounded-credential-liveness) —
without which an offboarded user's mirror row, and their outstanding
credentials, would freeze at their healthiest state), existing only so
machines, policies, and telemetry have something stable to point at. Single
team per machine/user — no multi-team precedence rules in v1.

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
2. The gateway validates that token per call — statelessly, against
   `meshum_web`'s published JWKS, never by reading the AS's storage (see
   [Gateway token validation](#gateway-token-validation-jwks)) — and checks
   org/team allow-block policy (see [governance.md](governance.md)).
3. If the call targets an upstream tool (Jira, GitHub, …), the gateway
   exchanges (RFC 8693 token-exchange semantics) the caller's Meshum token
   for a per-user, upstream-tool-scoped token, using an upstream connection
   the employee set up themselves in advance (see below). **This exchange is
   entirely gateway-internal — there is no client-facing token-exchange HTTP
   endpoint.** The harness never sees or handles the upstream credential; the
   gateway resolves it, refreshes it if expired, and uses it to make the
   upstream call itself, returning only the tool result over MCP. Per
   [architecture.md](architecture.md#serverappsmeshum_gateway--the-mcp-proxy-elixirphoenix),
   the gateway aggregates upstream tools under its own single MCP server
   identity with `<upstream>.<tool_name>` namespacing (e.g. `jira.get_issue`)
   — that namespace prefix is exactly what tells this step which
   `UpstreamServer`/connection to resolve.
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

#### Gateway token validation (JWKS)

Axis A access tokens are **signed JWTs** (the RFC 9068 JWT-access-token
profile): `sub` = the `UserRef`, `aud` = the gateway, `exp` ≈ 10 minutes
(short-lived). The gateway validates each call's token by checking its
signature against `meshum_web`'s published **JWKS** (fetched and cached) and
its `aud`/`exp` against expected values — **stateless, per-call, with no
network hop to the AS.**
It never reads the AS's storage and never depends on `boruta` internals.

- **Per-call introspection (RFC 7662) was considered and rejected for the hot
  path.** Introspection buys instant revocation, but at the cost of a network
  round-trip to the AS on every tool call. JWT + short TTL bounds the
  revocation window instead, and revocation is gated at the refresh grant (see
  [Bounded credential liveness](#bounded-credential-liveness)) — not on the
  per-call path.
- **Single data owner; the gateway owns no data.** `boruta` and all token
  issuance live behind `meshum_web` (the authorization server). The gateway's
  **only two contact surfaces** are (a) the public JWKS endpoint above and
  (b) `meshum`'s function API — for `ToolAccess` decisions and
  `UpstreamConnection` resolution, consistent with the "all schema and
  evaluation logic live in `server/apps/meshum`" rule in
  [architecture.md](architecture.md#serverappsmeshum--shared-business-logic-elixir).
  This keeps the gateway decoupled from the AS implementation and separable
  from the umbrella later. (Where surface (b) crosses a process boundary —
  the gateway fetching policy — that hop is authenticated by the
  [gateway ↔ control plane trust](#gateway--control-plane-trust)
  deployment-level shared secret; surface (a) needs no secret, the JWKS is
  public.)

#### Registering an upstream (admin)

Registering an `UpstreamServer` collapses to **"paste the upstream MCP URL"**
(e.g. GitHub at `https://api.githubcopilot.com/mcp/`). `meshum_web` then
probes that URL **as a spec-compliant MCP client** and obtains the OAuth
client credentials itself, rather than asking the admin to supply them:

1. Unauthenticated request → `401` → the upstream's **RFC 9728
   protected-resource metadata** → its **authorization-server metadata
   (RFC 8414)**.
2. **If the upstream AS advertises a registration endpoint**, Meshum
   dynamically registers itself via **Dynamic Client Registration (RFC 7591)**
   — **one client registration per deployment**, `redirect_uris` pointing at
   `meshum_web`'s callback — and stores the issued credentials on
   `UpstreamServer` with `provenance: dynamic`.
3. **If no DCR is advertised**, the UI falls back to **manual entry** of a
   client id/secret (`provenance: manual`). Manual is the fallback, not the
   default.

Both provenances yield an **identical row downstream**: a `url` plus usable
client credentials. Nothing after this point differs by provenance.

- **Rationale — symmetry.** Meshum consumes the exact same discovery/DCR
  handshake *as a client* toward upstreams that it *serves* toward harnesses
  (Axis A step 1 above): an upstream you can install by pointing Claude at a
  bare URL should be installable in Meshum the same way. DCR support among
  upstream authorization servers is uneven in practice, hence the manual
  fallback. (Implementation note: verify GitHub's actual DCR behaviour at
  implementation time.)
- **Everything downstream is unchanged.** Per-employee `UpstreamConnection`
  consent (below), gateway-internal token exchange (Axis A step 3), and
  employee-as-actor at the upstream (step 4) are exactly as before — this
  amendment only changes how the admin obtains the `UpstreamServer`'s own
  client credentials.

**Upstream connections are self-serve and proactive, not lazy.** An employee
logs into `meshum_web` directly and explicitly connects each upstream
account (Jira, GitHub, …) there — a one-time OAuth consent per tool — before
ever touching an AI harness. There is no admin bulk-provisioning of per-user
upstream identity in v1: each employee connects their own account.

### Axis B — daemon ↔ control plane (sync)

The daemon on an employee's machine polls `meshum_web` to sync its
`Manifest` — skills/agents/config — locally (see
[architecture.md](architecture.md#daemon--the-client-daemon-rust)). This
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
  enrollment). Enrollment issues a refresh credential; the daemon exchanges it
  for a short-lived access token every poll cycle. The refresh credential is
  **not** unbounded — it carries the same absolute lifetime as an Axis A
  refresh token, and the daemon re-runs this loopback enrollment (silent under
  a warm IdP session) when that bound expires, so an offboarded user's machine
  cannot keep syncing indefinitely (see
  [Bounded credential liveness](#bounded-credential-liveness)). On an
  already-enrolled machine that re-run rotates the existing `Machine`'s
  `MachineCredential` — it never creates a second `Machine` row.

The daemon's own status/capability/error reporting is **not** part of this
sync poll — it is a deliberately separate channel (different endpoint,
different implementation) so the two fail independently, using the same
`MachineCredential` for verified attribution. See
[daemon-reconciliation.md](daemon-reconciliation.md#reporting-machine-health-and-incidents).

## Bounded credential liveness

> Decided by Wannes Gennar, 2026-07-18.

**Problem.** `UserRef`/`TeamRef` mirror rows refresh only at login (see
[Identity ownership](#identity-ownership)), so an IdP-revoked (offboarded)
user's row freezes at its healthiest state — and, worse, their outstanding
credentials (harness refresh token, daemon `MachineCredential`, stored
upstream tokens) would keep working **indefinitely**. For a governance
product, retained access after offboarding is the headline risk; the stale
dashboard row is only the symptom. The fix is twofold: every issuance
re-checks the local `status` mirror, and every credential chain is forced
back through a **fresh IdP round-trip at least once per bounded window**
(stored upstream tokens carry no bound of their own — they are exercisable
only through a live, bounded Axis A token, so they are gated transitively):

- **Refresh grants are a revocation gate.** Before issuing a new access
  token, `meshum_web` re-checks the `UserRef`'s `status`. The grant itself
  never contacts the IdP, so this gate only bites once something has flipped
  that status — a manual offboarding action in v1, SCIM later. IdP-side
  revocation that nothing has mirrored into `status` propagates through the
  absolute lifetime bound below instead, not through this gate.
- **Refresh tokens have a bounded absolute lifetime (~7 days, configurable).**
  They cannot be renewed past it; only a fresh IdP-federated interactive
  re-auth (silent under a warm SSO session) issues new ones. Worst-case
  retained access after IdP revocation is exactly this bound.
- **Axis B machine credentials carry the same absolute bound.** When it
  expires, the daemon re-runs its loopback flow (see
  [Axis B](#axis-b--daemon--control-plane-sync)) — silent under warm SSO —
  re-issuing the existing `Machine`'s credential rather than refreshing
  indefinitely (it never enrolls a duplicate `Machine`).
- **`UserRef.last_verified_at` is stamped at every successful IdP
  round-trip** — web login, Axis A auth/re-auth, and Axis B enrollment.
  Dashboards treat rows older than the bound as **inactive** (a view derived
  from `last_verified_at`; an explicit `status` flip — manual offboarding
  now, SCIM later — also marks it): flagged and
  filtered from active views, but **never deleted** — a departed employee's
  historical telemetry must stay attributable. Schema should therefore leave
  room for a `status` field on `UserRef` (active/inactive), not just
  timestamps (see [Schema sketch](#schema-sketch)).

**Later, authoritative fix (post-v1): SCIM 2.0 inbound provisioning.** Entra
and Okta both support pushing user-lifecycle events; consuming them gives
near-real-time deactivation instead of a bounded-window lag. This is
explicitly **post-v1** and was chosen over periodic per-IdP directory
polling, which would need exactly the per-customer glue
[`assent`](#login-flow-implementation) was chosen to avoid. The
bounded-liveness mechanism above is the v1
answer; SCIM tightens the window later.

## Telemetry ingestion auth

A harness that emits OpenTelemetry natively (Claude Code) sends it **directly
to `meshum_web`**, not through the gateway or the daemon — see
[architecture.md](architecture.md#communication) and
[governance.md](governance.md#telemetry). This is a **third relationship**,
separate from both axes above.

**The endpoint requires a bearer token — it is not open/unauthenticated.**
Claude Code's OTel exporter supports sending an `Authorization` header, so
this is enforceable from the harness side.

**v1 only validates that a token is present, not what
it is or who it identifies.** No introspection, no signature check — any
non-empty bearer token is accepted. This is a deliberate v1 simplification,
not a permanent stance: it keeps the endpoint from being wide open (bare
HTTP, no header) without committing to one of the three verified-attribution
mechanisms below before the event-shape spike (see
[control-plane.md](control-plane.md#telemetry)) settles what's actually in
the payload. Consequence: the `user_ref_id`/`machine_id` a later aggregation
job derives for a `TelemetryEvent` cannot be trusted as verified in v1 —
they'd have to come from self-reported OTel attributes (e.g. `user.email` on
individual log records/metric data points, not resource-level attributes)
until real attribution is built. Candidates for
that later, verified version of this endpoint (not chosen, revisit once the
payload spike lands):

- Reuse the harness's Axis A OAuth token. `meshum_web` is the AS itself, so
  it can introspect locally with no cross-app hop, and gets verified user
  identity for free. Open question: what happens if a harness sends
  telemetry before ever completing the Axis A handshake (e.g. before its
  first MCP tool call)?
- A deployment-linked shared token (like the gateway↔web shared secret
  below) — doesn't identify *who* sent an event by itself.
- Axis A token when available, falling back to the daemon's existing Axis B
  machine credential when the daemon/hooks are the ones forwarding — both
  branches yield verified attribution, no self-report needed.

**Current direction (informal):** most likely a
deployment-linked shared secret (option 2 above), not a per-user/per-machine
token — telemetry configuration (`OTEL_EXPORTER_OTLP_ENDPOINT`/`_HEADERS`)
is typically synced out to every machine via company-wide settings, not
issued per user. A spike ingesting real Claude Code OTel exports (see
[control-plane.md](control-plane.md#observed-event-shapes-spike-findings-2026-07-10--claude-code-only))
found that **every event self-reports `user.email` in its payload**
regardless of what the auth token proves, so a shared-secret-only auth
model doesn't actually block per-user attribution — it just moves
attribution out of the (unverified) auth layer and into a later job that
reads the payload directly. This is a direction, not a closed decision —
still needs the "short round" this section already calls for, and the
sample is Claude-Code-only so far.

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
- `UserRef` — cached IdP user, belongs to a `TeamRef`. Carries
  `last_verified_at` (stamped at every successful IdP round-trip) and room for
  a `status` field (active/inactive) so offboarded users can be flagged and
  filtered without deleting their attributable history — see
  [Bounded credential liveness](#bounded-credential-liveness).
- `Machine` — belongs to an owning `UserRef` (team resolved transitively, no
  separate team field); has a `name` (auto-populated at enrollment,
  renameable) and a rotating `MachineCredential`; created atomically at the
  loopback-redirect enrollment callback, no separate code-exchange entity.
  Also carries the daemon's upserted self-reported state — its compiled
  `(operation, version)` capability table, its build/release version, and a
  health/last-seen signal — overwritten on every report (see
  [daemon-reconciliation.md](daemon-reconciliation.md#reporting-machine-health-and-incidents)).
- `MachineIncident` — append-only errors from a `Machine`'s daemon
  (`operation`, `version`, `message`, `occurred_at`), written only when an
  operation fails or is refused; distinct from the upserted `Machine` state
  above (see
  [daemon-reconciliation.md](daemon-reconciliation.md#reporting-format)).
- `ToolAccess` — org-wide or team-scoped MCP allow/block rules (runtime,
  gateway-consumed per call, fails closed). The other half — declarative
  desired state — is the `Manifest`, which is not a schema row here but a
  document over `Distributable`/config (see
  [control-plane.md](control-plane.md#version-controlled-desired-state-yaml)).
- `UpstreamServer` — a registered upstream MCP tool (Jira, GitHub, …): its
  `url` plus Meshum's own OAuth client credentials with it, and a `provenance`
  (`dynamic` — obtained via RFC 7591 DCR — or `manual`). Both provenances
  yield the same usable shape downstream — see
  [Registering an upstream (admin)](#registering-an-upstream-admin).
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
