defmodule Meshum.Repo.Migrations.ClientsJwksUri do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ClientsJwksUri (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ClientsJwksUri`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:jwks_uri, :string)
    end
  end
end
