defmodule Meshum.Repo.Migrations.SignedUserinfoResponse do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.SignedUserinfoResponse (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.SignedUserinfoResponse`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:userinfo_signed_response_alg, :string)
    end
  end
end
