defmodule Meshum.Repo.Migrations.ClientAuthenticationMethods do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ClientAuthenticationMethods (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ClientAuthenticationMethods`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def change do
    alter(table(:oauth_clients)) do
      add(:jwt_public_key, :text)
    end

    alter(table(:oauth_clients)) do
      add(:token_endpoint_auth_methods, {:array, :string},
        null: false,
        default: ["client_secret_basic", "client_secret_post"]
      )
    end

    alter(table(:oauth_clients)) do
      add(:token_endpoint_jwt_auth_alg, :string, default: "HS256", null: false)
    end
  end
end
