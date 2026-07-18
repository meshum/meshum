defmodule Meshum.Repo.Migrations.StorePreviousToken do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.StorePreviousToken (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.StorePreviousToken`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_tokens)) do
      add(:previous_token, :string)
    end
  end
end
