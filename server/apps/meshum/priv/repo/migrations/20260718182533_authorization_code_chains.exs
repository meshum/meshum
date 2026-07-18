defmodule Meshum.Repo.Migrations.AuthorizationCodeChains do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.AuthorizationCodeChains (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.AuthorizationCodeChains`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_tokens)) do
      add(:previous_code, :string)
    end
  end
end
