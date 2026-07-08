# MeshumWeb

The control plane: the Phoenix LiveView web interface where organizations see
their AI usage and manage and deploy their policies, hooks, and distributed
tooling. Changes made here are synced to the gateway (server side) and the
daemons on employee machines (client side). Shared logic lives in
[`meshum`](../meshum).

Start it with `mix phx.server` from the umbrella root (`server/`) and visit
[`localhost:4000`](http://localhost:4000).
