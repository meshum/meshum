defmodule Meshum.Repo.Migrations.ConfidentialClients do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ConfidentialClients (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ConfidentialClients`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:confidential, :boolean, default: false, null: false)
    end
  end
end
