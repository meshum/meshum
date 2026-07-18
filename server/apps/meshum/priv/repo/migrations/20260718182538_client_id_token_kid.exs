defmodule Meshum.Repo.Migrations.ClientIdTokenKid do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ClientIdTokenKid (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ClientIdTokenKid`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:id_token_kid, :string)
    end
  end
end
