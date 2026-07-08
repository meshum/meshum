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
Claude Code) or through plugins (OpenCode). The daemon could help set those up
out of the box.

Telemetry is ingested by the **control plane** (`meshum_web`). Ingestion might
get split out into a separate OTel collector component later.

## MCP control

The initial goal is to **filter MCP servers/tools**: since the gateway proxies
MCP calls (it's just JSON underneath), it can filter out tools that aren't
allowed.

v1 scope: **allowing/blocking servers + tools through the gateway.** Nothing
beyond that on the policy side — but note this is enforced *in addition to*,
not instead of, per-user upstream credential exchange, which is also v1
scope: the gateway exchanges the caller's identity for a per-user upstream
token (rather than a shared service credential) before proxying a call, so
that upstream tools' native authorization and audit trails keep working. See
[identity.md](identity.md#axis-a--ai-harness--gateway-the-mcp-tool-call-path)
for the full flow.

## Skill/agent distribution

In scope for v1.

- **Source of truth: the control plane.** Organisations author/upload skills
  and agents in `meshum_web`; the server stores them and the daemon syncs them
  down.
- **Installation is harness-dependent.** The daemon has per-harness adapters
  that install via whatever mechanism each supported AI client uses natively.
  v1 ships the **Claude Code adapter only**.
- **Scoping matches policies:** org-wide with team-level overrides.
- **Managed state:** the daemon re-syncs on drift — a skill removed locally
  gets restored. This is managed state, not blocking; the philosophy above
  still applies.
- **Versioning: latest-only.** The control plane holds one current version per
  skill/agent; daemons converge to it. No pinning or rollback in v1.

## Policy granularity

v1: policies are **org-wide and scoped** — a global policy with **team-level
overrides**.

## Explicitly out of scope for v1

Advanced features beyond the basic governance above, including:

- audit logs
- approval flows
- per-user / per-machine overrides
