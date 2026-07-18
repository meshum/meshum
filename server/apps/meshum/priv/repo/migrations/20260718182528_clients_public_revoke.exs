defmodule Meshum.Repo.Migrations.ClientsPublicRevoke do
  use Ecto.Migration

  # Vendored from Boruta.Migrations.ClientsPublicRevoke (boruta ~> 2.3).
  # `meshum` does not depend on `boruta` (see docs/architecture.md); this is
  # the exact macro-expansion of `use Boruta.Migrations.ClientsPublicRevoke`,
  # extracted mechanically (parsed + Macro.to_string, not hand-transcribed).
  def up do
    alter(table(:oauth_clients)) do
      add(:public_revoke, :boolean, null: false, default: false)
    end

    execute(
      "ALTER TABLE oauth_clients\n  ALTER COLUMN supported_grant_types TYPE varchar(255)[]\n    USING (supported_grant_types || ARRAY['revoke'::varchar(255), 'introspect'::varchar(255)])\n"
    )

    execute(
      " ALTER TABLE oauth_clients\n   ALTER COLUMN supported_grant_types\n     SET DEFAULT ARRAY['client_credentials', 'password', 'authorization_code', 'refresh_token', 'implicit', 'revoke', 'introspect']\n"
    )
  end

  def down do
    execute(
      "ALTER TABLE oauth_clients\n  ALTER COLUMN supported_grant_types TYPE varchar(255)[]\n    USING array_remove(supported_grant_types, 'revoke')\n"
    )

    execute(
      "ALTER TABLE oauth_clients\n  ALTER COLUMN supported_grant_types TYPE varchar(255)[]\n    USING array_remove(supported_grant_types, 'introspect')\n"
    )

    execute(
      " ALTER TABLE oauth_clients\n   ALTER COLUMN supported_grant_types\n     SET DEFAULT ARRAY['client_credentials', 'password', 'authorization_code', 'refresh_token', 'implicit']\n"
    )

    alter(table(:oauth_clients)) do
      remove(:public_revoke)
    end
  end
end
