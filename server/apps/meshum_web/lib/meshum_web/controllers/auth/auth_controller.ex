defmodule MeshumWeb.Controllers.Auth.AuthController do
  @moduledoc """
  Drives the OAuth/OIDC sign-in flow via `MeshumWeb.Auth.Provider`.

  `login/2` redirects to the provider's authorization URL, persisting the
  `session_params` it returns; `callback/2` completes the flow with those
  session params and the callback request's query params, then stores the
  signed-in user via `MeshumWeb.Plugs.Auth.set_current_user/2`; `logout/2`
  clears the session.
  """

  use MeshumWeb, :controller

  alias MeshumWeb.Auth.Provider

  @doc "Renders the sign-in page listing each configured provider"
  def login_page(conn, params) do
    render(conn, "login.html", params: params)
  end

  @doc "Handles the Assent login challenge"
  def login(conn, params) do
    provider_name = Map.get(params, "provider")

    with {:ok, provider} <- Provider.to_provider(provider_name),
         {:ok, %{url: url, session_params: session_params}} <- Provider.authorize_url(provider) do
      conn
      |> put_session("#{provider}_session_params", session_params)
      |> redirect(external: url)
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> render(:error, reason: reason)
    end
  end

  @doc "Handles the Assent callback"
  def callback(conn, params) do
    provider_name = Map.get(params, "provider")

    with {:ok, provider} <- Provider.to_provider(provider_name),
         session_params <- get_session(conn, "#{provider}_session_params"),
         {:ok, %{user: user}} <- Provider.callback(provider, params, session_params) do
      conn
      |> delete_session("#{provider}_session_params")
      |> MeshumWeb.Plugs.Auth.set_current_user(user)
      |> redirect(to: "/")
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> render(:error, reason: reason)
    end
  end

  @doc "Clears the session and redirects to the home page"
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
