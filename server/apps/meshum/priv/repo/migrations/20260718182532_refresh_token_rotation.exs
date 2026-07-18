defmodule Meshum.Repo.Migrations.RefreshTokenRotation do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.RefreshTokenRotation (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.RefreshTokenRotation`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_tokens)) do
      add(:refresh_token_revoked_at, :utc_datetime_usec)
    end
  end
end
