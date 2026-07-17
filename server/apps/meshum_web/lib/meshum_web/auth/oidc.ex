defmodule MeshumWeb.Auth.Oidc do
  @moduledoc """
  Meshum's OpenID Connect strategy.

  A thin wrapper around `Assent.Strategy.OIDC.Base` that runs the IdP's user
  claims through `Assent.Strategy.normalize_userinfo/2`. Standard OIDC
  claims are type-cast to their spec types (e.g. `email_verified` becomes a
  real boolean, integer-ish claims to integers), while any provider-specific
  extras (Keycloak's `realm_access`, Entra's `oid`/`tid`, Google's `hd`) are
  deep-merged back on top so they survive normalization.

  Prefer this over the bare `Assent.Strategy.OIDC`, whose `callback/3`
  skips `Assent.Strategy.__normalize__/3` and returns raw, un-cast ID-token
  claims — leaking type inconsistencies (e.g. `email_verified` arriving as
  the string `"true"` for some IdPs) into downstream consumers.

  ## Configuration

  All provider configuration is supplied through the application environment
  and merged at runtime by `MeshumWeb.Auth.Provider`; this module itself
  ships no defaults. Use it as the `:strategy` under
  `config :meshum_web, :auth_providers`:

      config :meshum_web, :auth_providers,
        oidc: [
          strategy: MeshumWeb.Auth.Oidc,
          client_id: "...",
          client_secret: "...",
          base_url: "https://idp.example.com"
        ]
  """

  use Assent.Strategy.OIDC.Base

  @doc """
  Returns the strategy's default configuration.

  Intentionally empty: every provider's `client_id`, `client_secret`, and
  `base_url` is sourced from `config :meshum_web, :auth_providers` and
  merged on top at call time by `Assent.Strategy.OIDC.Base.set_config/2`.
  """
  @impl true
  def default_config(_config), do: []
end
