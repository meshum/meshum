defmodule MeshumWeb.Plugs.Auth do
  @moduledoc """
  Contains authentication related plugs for the Meshum web interface.
  This plug checks if a user is logged in by verifying the presence of user information in the session.
  If the user is not logged in, it redirects them to the login page and halts further processing of the request.

  It also contains helper methods for setting the current user in the session and retrieving the current user from the session.
  """

  import Plug.Conn
  import Phoenix.Controller

  use MeshumWeb, :verified_routes

  @doc """
  If user information is present in the session, assigns it to `:current_user` in the connection.
  Otherwise, the connection remains unchanged.
  """
  def fetch_current_user(conn, _opts) do
    case get_current_user(conn) do
      nil ->
        conn

      user_info ->
        assign(conn, :current_user, user_info)
    end
  end

  @doc """
  Checks if a user is logged in. If not, redirects to the login page.
  """
  def requires_user(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: ~p"/auth/login")
        |> halt()

      _ ->
        conn
    end
  end

  @doc """
  Sets the given user information in the session as the current user.
  """
  def set_current_user(conn, user_info) do
    put_session(conn, :user_info, user_info)
  end

  @doc """
  Retrieves the current user information from the session.
  """
  def get_current_user(conn) do
    get_session(conn, :user_info)
  end
end
