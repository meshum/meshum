defmodule MeshumWeb.Auth.Provider do
  @moduledoc """
  Dispatches sign-in to the configured `Assent` strategy for a given
  provider.

  Each provider is configured under `config :meshum_web, :auth_providers` as
  a keyword list keyed by `t:provider/0`, e.g.:

      config :meshum_web, :auth_providers,
        oidc: [
          strategy: Assent.Strategy.OIDC,
          client_id: "...",
          client_secret: "...",
          site: "https://idp.example.com"
        ]

  The `:redirect_uri` entry is injected by this module (see `config!/1`)
  rather than configured statically, since it must match the host the
  request was served from and the callback route below.
  """

  @typedoc """
  The type of authentication provider supported by the application.
  """
  @type provider :: :oidc

  @callback_path "/auth/callback/:provider"

  @doc """
  Attempts to convert a string into a valid provider, returning `{:ok, provider}` or `{:error, reason}`.
  """
  @spec to_provider(String.t()) :: {:ok, provider()} | {:error, term()}
  def to_provider(name) do
    case name do
      "oidc" -> {:ok, :oidc}
      _ -> {:error, :unknown_provider}
    end
  end

  @doc """
  Lists the providers configured under `config :meshum_web, :auth_providers`,
  for rendering one SSO button per provider on the login screen.
  """
  @spec configured() :: [provider()]
  def configured do
    :meshum_web
    |> Application.get_env(:auth_providers, [])
    |> Keyword.keys()
  end

  @doc """
  Returns the authorization URL(s) for the given provider.

  Delegates to the provider's `Assent` strategy, e.g.
  `Assent.Strategy.OIDC.authorize_url/1`. The result includes the `:url` to
  redirect the user to, plus session params that must be persisted (e.g. in
  the Plug session) and passed back into `callback/3` on the OAuth/OIDC
  callback request.
  """
  @spec authorize_url(provider()) :: {:ok, map()} | {:error, term()}
  def authorize_url(provider) do
    config = config!(provider)

    config[:strategy].authorize_url(config)
  end

  @doc """
  Completes the OAuth/OIDC flow for the given provider.

  `params` are the callback request's query params (e.g. `code`, `state`),
  and `session_params` are the params returned by `authorize_url/1` and
  persisted across the redirect.
  """
  @spec callback(provider(), map(), map()) :: {:ok, map()} | {:error, term()}
  def callback(provider, params, session_params) do
    config = config!(provider)

    config
    |> Keyword.put(:session_params, session_params)
    |> then(&config[:strategy].callback(&1, params))
  end

  # Builds the strategy config for `provider`, injecting the `:redirect_uri`
  # that the identity provider must call back to.
  defp config!(provider) do
    config =
      Application.get_env(:meshum_web, :auth_providers)[provider] ||
        raise "No provider configuration for #{provider}"

    Keyword.put(config, :redirect_uri, callback_path(provider))
  end

  # Generates a valid callback URL for the given provider, e.g. `https://example.com/oauth/oidc/callback`.
  defp callback_path(provider) do
    MeshumWeb.Endpoint.url() <> String.replace(@callback_path, ":provider", to_string(provider))
  end
end
