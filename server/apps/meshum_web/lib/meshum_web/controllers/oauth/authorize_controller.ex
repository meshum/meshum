defmodule MeshumWeb.Controllers.Oauth.AuthorizeController do
  @moduledoc """
  The OAuth 2.0 `/oauth/authorize` endpoint: drives `Boruta.Oauth.authorize/3`
  through the `Boruta.Oauth.AuthorizeApplication` callbacks, resolving the
  resource owner from `conn.assigns[:current_user]`
  (a `MeshumWeb.Auth.User`) or redirecting to login when signed out.
  """

  @behaviour Boruta.Oauth.AuthorizeApplication

  use MeshumWeb, :controller

  alias Boruta.Oauth.AuthorizeResponse
  alias Boruta.Oauth.Error
  alias MeshumWeb.Auth.User
  alias MeshumWeb.Controllers.Oauth.OauthHTML

  @doc "The `Boruta.Oauth` implementation to dispatch to; overridden in tests via Mox."
  def oauth_module, do: Application.get_env(:meshum_web, :oauth_module, Boruta.Oauth)

  @doc "Authorizes the request for the signed-in user, or redirects to login."
  def authorize(%Plug.Conn{} = conn, _params) do
    current_user = conn.assigns[:current_user]
    conn = store_user_return_to(conn)

    authorize_response(
      conn,
      current_user
    )
  end

  defp authorize_response(conn, %User{} = current_user) do
    conn
    |> oauth_module().authorize(
      User.to_resource_owner(current_user),
      __MODULE__
    )
  end

  defp authorize_response(conn, _params) do
    redirect_to_login(conn)
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_success(
        conn,
        %AuthorizeResponse{} = response
      ) do
    redirect(conn, external: AuthorizeResponse.redirect_to_url(response))
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def authorize_error(
        %Plug.Conn{} = conn,
        %Error{status: :unauthorized}
      ) do
    redirect_to_login(conn)
  end

  def authorize_error(
        conn,
        %Error{format: format} = error
      )
      when not is_nil(format) do
    conn
    |> redirect(external: Error.redirect_to_url(error))
  end

  def authorize_error(
        conn,
        %Error{status: status, error: error, error_description: error_description}
      ) do
    conn
    |> put_status(status)
    |> put_view(OauthHTML)
    |> render("error.html", error: error, error_description: error_description)
  end

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_success(_conn, _response), do: :ok

  @impl Boruta.Oauth.AuthorizeApplication
  def preauthorize_error(_conn, _response), do: :ok

  defp store_user_return_to(conn) do
    conn
    |> put_session(
      :user_return_to,
      current_path(conn)
    )
  end

  defp redirect_to_login(_conn) do
    raise """
    Here occurs the login process. After login, user may be redirected to
    get_session(conn, :user_return_to)
    """
  end
end
