defmodule Meshum.Repo.Migrations.IdTokenSignatureAlgConfiguration do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.IdTokenSignatureAlgConfiguration (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.IdTokenSignatureAlgConfiguration`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:id_token_signature_alg, :string, default: "RS512")
    end
  end
end
