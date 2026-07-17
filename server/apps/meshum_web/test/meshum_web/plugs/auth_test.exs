defmodule MeshumWeb.Plugs.AuthTest do
  use MeshumWeb.ConnCase, async: true

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

  describe "MeshumWeb.Plugs.Auth.requires_user/2" do
    setup do
      %{user: MeshumWeb.Test.IdpUsers.github()}
    end

    test "assigns :current_user and continues when a user is in the session", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session(:user_info, user)
        |> fetch_flash()
        |> Auth.requires_user([])

      assert conn.assigns.current_user == user
      refute conn.halted
      assert conn.status != 302
    end

    test "redirects to /auth/login with a flash when no user is in the session", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> fetch_flash()
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

      test "requires_user/2 assigns the same map as :current_user", %{conn: conn} do
        conn =
          conn
          |> Plug.Test.init_test_session(%{})
          |> Auth.set_current_user(unquote(Macro.escape(user)))
          |> Auth.requires_user([])

        assert conn.assigns.current_user == unquote(Macro.escape(user))
      end
    end
  end
end
