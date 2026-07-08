# MeshumGateway

The MCP proxy. AI agents call the gateway as if it were the MCP server they
need (Jira, GitHub, …); because MCP calls are proxied here, the gateway can
filter out servers and tools the organization's policy doesn't allow. Policy
comes from the control plane ([`meshum_web`](../meshum_web)); shared logic
lives in [`meshum`](../meshum).

Start it with `mix phx.server` from the umbrella root (`server/`).
