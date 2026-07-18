defmodule MeshumWeb.Plugs.AuthTest do
  use MeshumWeb.ConnCase, async: true

  alias MeshumWeb.Auth.User
  alias MeshumWeb.Plugs.Auth

  describe "MeshumWeb.Plugs.Auth.set_current_user/2" do
    test "stores the user under :user_info in the session", %{conn: conn} do
      user = %{"name" => "Test User"}
      conn = conn |> Plug.Test.init_test_session(%{}) |> Auth.set_current_user(user)

      assert Plug.Conn.get_session(conn, :user_info) == user
    end

    test "is idempotent over consecutive calls — last write wins", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Auth.set_current_user(%{"name" => "First"})
        |> Auth.set_current_user(%{"name" => "Second"})

      assert Plug.Conn.get_session(conn, :user_info) == %{"name" => "Second"}
    end
  end

  describe "MeshumWeb.Plugs.Auth.get_current_user/1" do
    test "returns the user stored under :user_info", %{conn: conn} do
      user = %{"sub" => "abc", "name" => "Test"}

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_info, user)

      assert Auth.get_current_user(conn) == user
    end

    test "returns nil when :user_info is absent", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{})

      assert Auth.get_current_user(conn) == nil
    end
  end

  describe "MeshumWeb.Plugs.Auth.fetch_current_user/2" do
    test "assigns a MeshumWeb.Auth.User built from :user_info in the session", %{conn: conn} do
      user = MeshumWeb.Test.IdpUsers.github()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_info, user)
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == User.from_claims(user)
    end

    test "leaves the connection unchanged when :user_info is absent", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Auth.fetch_current_user([])

      refute Map.has_key?(conn.assigns, :current_user)
    end
  end

  describe "MeshumWeb.Plugs.Auth.requires_user/2" do
    setup do
      %{user: MeshumWeb.Test.IdpUsers.github()}
    end

    test "continues without redirecting when :current_user is already assigned", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_info, user)
        |> fetch_flash()
        |> Auth.fetch_current_user([])
        |> Auth.requires_user([])

      assert conn.assigns.current_user == User.from_claims(user)
      refute conn.halted
      assert conn.status != 302
    end

    test "redirects to /auth/login with a flash when no :current_user is assigned", %{
      conn: conn
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> fetch_flash()
        |> Auth.fetch_current_user([])
        |> Auth.requires_user([])

      assert conn.halted
      assert redirected_to(conn) == "/auth/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "You must be logged in"
    end
  end

  # Parametrized across every realistic IdP user shape: the user map
  # stored by `set_current_user/2` must round-trip through the session
  # unchanged, with no field loss, type coercion, or key reordering that
  # would matter for downstream consumers (e.g. `Layouts.user_display_name/1`).
  for {label, user} <- MeshumWeb.Test.IdpUsers.shapes() do
    describe "MeshumWeb.Plugs.Auth session roundtrip with #{label} shape" do
      test "set_current_user/2 then get_current_user/1 returns the same map", %{conn: conn} do
        conn =
          conn
          |> Plug.Test.init_test_session(%{})
          |> Auth.set_current_user(unquote(Macro.escape(user)))

        assert Auth.get_current_user(conn) == unquote(Macro.escape(user))
      end

      test "fetch_current_user/2 then requires_user/2 assigns a User built from the same claims",
           %{conn: conn} do
        conn =
          conn
          |> Plug.Test.init_test_session(%{})
          |> Auth.set_current_user(unquote(Macro.escape(user)))
          |> Auth.fetch_current_user([])
          |> Auth.requires_user([])

        authenticated_at = Plug.Conn.get_session(conn, :authenticated_at)

        assert conn.assigns.current_user ==
                 User.from_claims(unquote(Macro.escape(user)), authenticated_at)
      end
    end
  end
end
