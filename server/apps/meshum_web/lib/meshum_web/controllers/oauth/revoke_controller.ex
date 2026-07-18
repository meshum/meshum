defmodule MeshumWeb.Controllers.Oauth.RevokeController do
  @behaviour Boruta.Oauth.RevokeApplication

  use MeshumWeb, :controller

  alias Boruta.Oauth.Error
  alias MeshumWeb.Controllers.Oauth.OauthJSON

  @doc "The `Boruta.Oauth` implementation to dispatch to; overridden in tests via Mox."
  def oauth_module, do: Application.get_env(:meshum_web, :oauth_module, Boruta.Oauth)

  def revoke(%Plug.Conn{} = conn, _params) do
    conn |> oauth_module().revoke(__MODULE__)
  end

  @impl Boruta.Oauth.RevokeApplication
  def revoke_success(%Plug.Conn{} = conn) do
    send_resp(conn, 200, "")
  end

  @impl Boruta.Oauth.RevokeApplication
  def revoke_error(conn, %Error{
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
