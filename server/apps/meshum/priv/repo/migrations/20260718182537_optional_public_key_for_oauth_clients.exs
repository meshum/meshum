defmodule Meshum.Repo.Migrations.OptionalPublicKeyForOauthClients do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.OptionalPublicKeyForOauthClients (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.OptionalPublicKeyForOauthClients`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def up do
    alter(table(:oauth_clients)) do
      modify(:public_key, :text, null: true)
    end
  end

  def down do
    alter(table(:oauth_clients)) do
      modify(:public_key, :text, null: false)
    end
  end
end
