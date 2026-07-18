defmodule MeshumWeb.Auth.User do
  @moduledoc """
  A normalized signed-in user, built from the raw IdP claims map
  `MeshumWeb.Plugs.Auth` carries in the session.

  Every IdP shape only guarantees `sub` (see
  `MeshumWeb.Test.IdpUsers` for the documented variance across
  providers) — no provider ever sends an `"id"` claim, and `email`/`name`
  can be absent or `nil`. Consumers that used to dot-access the raw claims
  map directly (expecting struct-like fields that were never there) are the
  reason this exists: build the common fields once, here, and keep the raw
  claims reachable via `claims` for anything that needs a provider-specific
  extra (Entra's `oid`, Keycloak's `realm_access`, ...).

  This type is `meshum_web`-private: neither `meshum` nor `meshum_gateway`
  has (or should have) any concept of this struct — the umbrella dependency
  graph doesn't let them depend on `meshum_web` in the first place.
  """

  @enforce_keys [:sub, :claims]
  defstruct [:sub, :email, :display_name, :authenticated_at, :claims]

  @type t :: %__MODULE__{
          sub: String.t(),
          email: String.t() | nil,
          display_name: String.t() | nil,
          authenticated_at: DateTime.t() | nil,
          claims: %{optional(String.t()) => term()}
        }

  @doc """
  Builds a normalized user from a raw IdP claims map and the timestamp of
  the IdP round-trip that produced it (`nil` for sessions issued before
  this field existed).
  """
  @spec from_claims(map(), DateTime.t() | nil) :: t()
  def from_claims(claims, authenticated_at \\ nil) do
    %__MODULE__{
      sub: Map.fetch!(claims, "sub"),
      email: claims["email"],
      display_name: claims["name"] || claims["preferred_username"] || claims["email"],
      authenticated_at: authenticated_at,
      claims: claims
    }
  end

  @doc """
  Maps a normalized user onto the `Boruta.Oauth.ResourceOwner` the OAuth/OIDC
  authorize controllers hand to `boruta`.
  """
  @spec to_resource_owner(t()) :: Boruta.Oauth.ResourceOwner.t()
  def to_resource_owner(%__MODULE__{} = user) do
    %Boruta.Oauth.ResourceOwner{
      sub: user.sub,
      username: user.email,
      last_login_at: user.authenticated_at
    }
  end
end
