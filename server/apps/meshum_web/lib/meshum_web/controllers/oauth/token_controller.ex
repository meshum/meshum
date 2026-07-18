defmodule MeshumWeb.Controllers.Oauth.TokenController do
  @moduledoc """
  The OAuth 2.0 `/oauth/token` endpoint: delegates every grant type to
  `Boruta.Oauth.token/2` and renders the resulting `TokenResponse` (or error)
  via the `Boruta.Oauth.TokenApplication` callbacks. Also backs the OIDC
  token endpoint — an `id_token` simply appears in the same response when the
  grant included the `openid` scope.
  """

  @behaviour Boruta.Oauth.TokenApplication

  use MeshumWeb, :controller

  alias Boruta.Oauth.Error
  alias Boruta.Oauth.TokenResponse
  alias MeshumWeb.Controllers.Oauth.OauthJSON

  @doc "The `Boruta.Oauth` implementation to dispatch to; overridden in tests via Mox."
  def oauth_module, do: Application.get_env(:meshum_web, :oauth_module, Boruta.Oauth)

  @doc "Exchanges the request's grant for a token."
  def token(%Plug.Conn{} = conn, _params) do
    conn |> oauth_module().token(__MODULE__)
  end

  @impl Boruta.Oauth.TokenApplication
  def token_success(conn, %TokenResponse{} = response) do
    conn
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("cache-control", "no-store")
    |> put_view(OauthJSON)
    |> render("token.json", response: response)
  end

  @impl Boruta.Oauth.TokenApplication
  def token_error(conn, %Error{status: status, error: error, error_description: error_description}) do
    conn
    |> put_status(status)
    |> put_view(OauthJSON)
    |> render("error.json", error: error, error_description: error_description)
  end
end
