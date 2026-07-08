# Meshum server

Elixir umbrella housing Meshum's server side. It is composed of three apps:

- [`meshum`](apps/meshum) — shared business logic between the gateway and web.
- [`meshum_gateway`](apps/meshum_gateway) — the MCP proxy AI agents talk to.
- [`meshum_web`](apps/meshum_web) — the control plane web interface.

See [`docs/architecture.md`](../docs/architecture.md) for what each does and
how they communicate. The umbrella defines separate `meshum_gateway` and
`meshum_web` releases; they can run on the same machine.

## Development

- `mix setup` installs and sets up dependencies (Postgres required; the repo
  root `compose.yaml` provides one).
- `mix phx.server` (or `iex -S mix phx.server`) starts the endpoints; the web
  interface is at [`localhost:4000`](http://localhost:4000).
- `mix precommit` / `just elixir` from the repo root run the analysis suite.
