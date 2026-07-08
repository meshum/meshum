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

Where telemetry data is ingested/flows to: **provisionally the web interface**
(control plane) — the user's working assumption, but explicitly *not* a hard
decision yet.

## MCP control

The initial goal is to **filter MCP servers/tools**: since the gateway proxies
MCP calls (it's just JSON underneath), it can filter out tools that aren't
allowed.

v1 scope: **allowing/blocking servers + tools through the gateway.** Nothing
beyond that.

## Skill/agent distribution

`UNDECIDED` — to be discussed at a later point.

## Policy granularity

v1: policies are **org-wide and scoped** — a global policy with **team-level
overrides**.

## Explicitly out of scope for v1

Advanced features beyond the basic governance above, including:

- audit logs
- approval flows
- per-user / per-machine overrides
