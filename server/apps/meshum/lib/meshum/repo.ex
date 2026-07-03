defmodule Meshum.Repo do
  use Ecto.Repo,
    otp_app: :meshum,
    adapter: Ecto.Adapters.Postgres
end
