defmodule Meshum.Repo.Migrations.AddMetadataToClients do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.AddMetadataToClients (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.AddMetadataToClients`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:metadata, :jsonb, default: "{}", null: false)
      add(:logo_uri, :string)
    end
  end
end
