defmodule Meshum.Repo do
  @moduledoc """
  Meshum's Ecto repository, backed by PostgreSQL.
  """
  use Ecto.Repo,
    otp_app: :meshum,
    adapter: Ecto.Adapters.Postgres
end
