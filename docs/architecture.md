# Architecture

> Status: draft — decided by Wannes Gennar, 2026-07-08. Items marked
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

### `server/apps/meshum_gateway` — the MCP proxy (Elixir/Phoenix)

An **MCP proxy** running on the server. AI agents call the gateway **as if it
were the MCP server they need** (Jira, GitHub, …).

### `server/apps/meshum_web` — the control plane (Elixir/Phoenix LiveView)

The web interface / **control plane**. This is where organisations see, manage
and deploy their policies, hooks, and so forth. Those changes get synced out to
the gateway (server side) and the daemon (client side).

### `server/apps/meshum` — shared business logic (Elixir)

Shared business logic between the gateway and web apps.

## Communication

- **daemon → web**: the daemon talks to the control plane (`meshum_web`).
- **gateway → web**: the gateway talks to the control plane (`meshum_web`).
- **gateway ↮ daemon**: the gateway and daemon do **not** talk to each other.
- Communication method/protocol: **HTTP polling for the MVP** — both daemon →
  web and gateway → web. This implies a **poll** sync model: changes propagate
  on the poll interval. Better/other sync methods (push via WebSocket, gRPC, …)
  can be added later.

## Deployment model

- Meshum is **self-hosted by organisations**; a **hosted offering** exists for
  companies that want it.
- The **daemon is always deployed to employee/client computers**.
- **web and gateway** can run on the same machine, in Docker, K8s, ….
