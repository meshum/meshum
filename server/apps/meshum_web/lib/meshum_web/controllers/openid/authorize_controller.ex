defmodule MeshumWeb.Controllers.Openid.AuthorizeController do
  @moduledoc """
  The OIDC `/openid/authorize` endpoint: the same authorization flow as
  `MeshumWeb.Controllers.Oauth.AuthorizeController`, plus the OIDC-specific
  `prompt`/`max_age` redirections (`prompt=login` forces a fresh login,
  `prompt=none` errors instead of prompting, `max_age` forces re-login once
  the resource owner's last login is stale) before delegating to
  `Boruta.Oauth.authorize/3` via the `Boruta.Oauth.AuthorizeApplication`
  callbacks.
  """

  @behaviour Boruta.Oauth.AuthorizeApplication

  use MeshumWeb, :controller

  alias Boruta.Oauth.AuthorizeResponse
  alias Boruta.Oauth.Error
  alias Boruta.Oauth.ResourceOwner
  alias MeshumWeb.Auth.User
  alias MeshumWeb.Controllers.Oauth.OauthHTML

  @doc "The `Boruta.Oauth` implementation to dispatch to; overridden in tests via Mox."
  def oauth_module, do: Application.get_env(:meshum_web, :oauth_module, Boruta.Oauth)

  @doc """
  Authorizes the request, applying the OIDC `prompt`/`max_age` redirections
  before falling through to the same authorization Boruta performs for
  plain OAuth.
  """
  def authorize(%Plug.Conn{} = conn, _params) do
    conn = store_user_return_to(conn)

    resource_owner = get_resource_owner(conn)

    with {:unchanged, conn} <- prompt_redirection(conn),
         {:unchanged, conn} <- max_age_redirection(conn, resource_owner),
         {:unchanged, conn} <- login_redirection(conn) do
      oauth_module().authorize(conn, resource_owner, __MODULE__)
    end
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
        %Error{status: :unauthorized, error: :login_required} = error
      ) do
    redirect(conn, external: Error.redirect_to_url(error))
  end

  def authorize_error(
        %Plug.Conn{} = conn,
        %Error{status: :unauthorized, error: :invalid_resource_owner}
      ) do
    redirect_to_login(conn)
  end

  def authorize_error(
        conn,
        %Error{
          format: format
        } = error
      )
      when not is_nil(format) do
    redirect(conn, external: Error.redirect_to_url(error))
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

  defp store_user_return_to(conn) do
    # remove prompt and max_age params affecting redirections
    conn
    |> put_session(
      :user_return_to,
      current_path(conn)
      |> String.replace(~r/prompt=(login|none)/, "")
      |> String.replace(~r/max_age=(\d+)/, "")
    )
  end

  defp prompt_redirection(%Plug.Conn{query_params: %{"prompt" => "login"}} = conn) do
    log_out_user(conn)
  end

  defp prompt_redirection(%Plug.Conn{} = conn), do: {:unchanged, conn}

  defp max_age_redirection(
         %Plug.Conn{query_params: %{"max_age" => max_age}} = conn,
         %ResourceOwner{} = resource_owner
       ) do
    case login_expired?(resource_owner, max_age) do
      true ->
        log_out_user(conn)

      false ->
        {:unchanged, conn}
    end
  end

  defp max_age_redirection(%Plug.Conn{} = conn, _resource_owner), do: {:unchanged, conn}

  defp login_expired?(%ResourceOwner{last_login_at: nil}, _max_age), do: false

  defp login_expired?(%ResourceOwner{last_login_at: last_login_at}, max_age) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    with "" <> max_age <- max_age,
         {max_age, _} <- Integer.parse(max_age),
         true <- now - DateTime.to_unix(last_login_at) >= max_age do
      true
    else
      _ -> false
    end
  end

  defp login_redirection(%Plug.Conn{assigns: %{current_user: _current_user}} = conn) do
    {:unchanged, conn}
  end

  defp login_redirection(%Plug.Conn{query_params: %{"prompt" => "none"}} = conn) do
    {:unchanged, conn}
  end

  defp login_redirection(%Plug.Conn{} = conn) do
    redirect_to_login(conn)
  end

  defp get_resource_owner(conn) do
    case conn.assigns[:current_user] do
      nil ->
        %ResourceOwner{sub: nil}

      %User{} = current_user ->
        User.to_resource_owner(current_user)
    end
  end

  defp redirect_to_login(_conn) do
    raise """
    Here occurs the login process. After login, user may be redirected to
    get_session(conn, :user_return_to)
    """
  end

  defp log_out_user(_conn) do
    raise """
    Here user shall be logged out then redirected to login. After login, user may be redirected to
    get_session(conn, :user_return_to)
    """
  end
end
