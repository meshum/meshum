defmodule Meshum.Repo.Migrations.ClientsRefreshTokens do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ClientsRefreshTokens (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ClientsRefreshTokens`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:public_refresh_token, :boolean, null: false, default: false)
    end

    alter(table(:oauth_clients)) do
      add(:refresh_token_ttl, :integer, null: false, default: "2592000")
    end
  end
end
