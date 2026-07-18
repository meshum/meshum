defmodule MeshumWeb.Controllers.Oauth.IntrospectController do
  @moduledoc """
  The OAuth 2.0 token introspection endpoint (RFC 7662):
  `Boruta.Oauth.introspect/2` reports whether a token is active, and this
  controller renders that result as JSON via the
  `Boruta.Oauth.IntrospectApplication` callbacks.
  """

  @behaviour Boruta.Oauth.IntrospectApplication

  use MeshumWeb, :controller

  alias Boruta.Oauth.Error
  alias Boruta.Oauth.IntrospectResponse
  alias MeshumWeb.Controllers.Oauth.OauthJSON

  @doc "The `Boruta.Oauth` implementation to dispatch to; overridden in tests via Mox."
  def oauth_module, do: Application.get_env(:meshum_web, :oauth_module, Boruta.Oauth)

  @doc "Introspects the token carried by the request."
  def introspect(%Plug.Conn{} = conn, _params) do
    conn |> oauth_module().introspect(__MODULE__)
  end

  @impl Boruta.Oauth.IntrospectApplication
  def introspect_success(conn, %IntrospectResponse{} = response) do
    conn
    |> put_view(OauthJSON)
    |> render("introspect.json", response: response)
  end

  @impl Boruta.Oauth.IntrospectApplication
  def introspect_error(conn, %Error{
        status: status,
        error: error,
        error_description: error_description
      }) do
    conn
    |> put_status(status)
    |> put_view(OauthJSON)
    |> render("error.json", error: error, error_description: error_description)
  end
end
