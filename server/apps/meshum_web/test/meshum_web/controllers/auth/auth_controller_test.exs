defmodule MeshumWeb.Controllers.Auth.AuthControllerTest do
  use MeshumWeb.ConnCase

  alias MeshumWeb.Test.FakeAssentStrategy

  # The whole module exercises Provider/AuthController dispatch, so the
  # fake OIDC strategy is wired in for every test.
  setup :setup_fake_oidc

  describe "MeshumWeb.Controllers.Auth.AuthController.login_page/2" do
    test "renders the login screen", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")
      assert html_response(conn, 200) =~ "Sign in to Meshum"
    end

    test "lists a sign-in link for each configured provider", %{conn: conn} do
      conn = get(conn, ~p"/auth/login")

      assert conn.resp_body =~
               ~s(href="/auth/login/oidc")
    end
  end

  describe "MeshumWeb.Controllers.Auth.AuthController.login/2" do
    test "redirects to the IdP authorize_url and persists session_params", %{conn: conn} do
      FakeAssentStrategy.with_authorize_url_result(
        {:ok, %{url: "https://idp.test/auth", session_params: %{state: "the-state"}}}
      )

      conn = get(conn, ~p"/auth/login/oidc")

      assert redirected_to(conn, 302) == "https://idp.test/auth"
      assert Plug.Conn.get_session(conn, "oidc_session_params") == %{state: "the-state"}
    end

    test "renders the error page with 400 when the provider is unknown", %{conn: conn} do
      conn = get(conn, ~p"/auth/login/nope")

      assert html_response(conn, 400) =~ "Something went wrong"
    end

    test "renders the error page with 400 when the strategy fails", %{conn: conn} do
      FakeAssentStrategy.with_authorize_url_result({:error, :no_openid_configuration})

      conn = get(conn, ~p"/auth/login/oidc")

      assert html_response(conn, 400) =~ "Something went wrong"
    end
  end

  describe "MeshumWeb.Controllers.Auth.AuthController.callback/2" do
    test "completes the flow, stores the user, clears session_params, and redirects home",
         %{conn: conn} do
      user = MeshumWeb.Test.IdpUsers.github()
      FakeAssentStrategy.with_callback_user(user)
      session_params = %{state: "the-state", code_verifier: "the-verifier"}

      conn =
        conn
        |> Plug.Test.init_test_session(%{"oidc_session_params" => session_params})
        |> get(~p"/auth/callback/oidc")

      assert redirected_to(conn, 302) == "/"
      assert Plug.Conn.get_session(conn, :user_info) == user
      assert Plug.Conn.get_session(conn, "oidc_session_params") == nil
    end

    test "forwards the stored session_params to Provider.callback/3", %{conn: conn} do
      FakeAssentStrategy.with_callback_user(MeshumWeb.Test.IdpUsers.github())
      session_params = %{state: "the-state", code_verifier: "the-verifier"}

      conn =
        conn
        |> Plug.Test.init_test_session(%{"oidc_session_params" => session_params})
        |> get(~p"/auth/callback/oidc")

      _ = conn

      assert FakeAssentStrategy.last_callback_config()[:session_params] == session_params
      assert FakeAssentStrategy.last_callback_params() == %{"provider" => "oidc"}
    end

    test "renders the error page with 400 when the provider is unknown", %{conn: conn} do
      conn = get(conn, ~p"/auth/callback/nope")

      assert html_response(conn, 400) =~ "Something went wrong"
    end

    test "renders the error page when session_params are absent (direct navigation)",
         %{conn: conn} do
      FakeAssentStrategy.with_callback_result({:error, :missing_session_params})

      conn = get(conn, ~p"/auth/callback/oidc")

      assert html_response(conn, 400) =~ "Something went wrong"
      assert FakeAssentStrategy.last_callback_config()[:session_params] == nil
    end

    test "renders the error page when the strategy rejects the callback", %{conn: conn} do
      FakeAssentStrategy.with_callback_result({:error, :invalid_state})

      conn =
        conn
        |> Plug.Test.init_test_session(%{"oidc_session_params" => %{state: "x"}})
        |> get(~p"/auth/callback/oidc")

      assert html_response(conn, 400) =~ "Something went wrong"
    end
  end

  # Parametrized across every realistic IdP user shape: the user map
  # returned by the strategy must survive the controller's session storage
  # unchanged, regardless of the IdP's claim shape.
  for {label, user} <- MeshumWeb.Test.IdpUsers.shapes() do
    @tag user_shape: label
    test "callback/2 roundtrips the #{label} user map unchanged through the session",
         %{conn: conn} do
      FakeAssentStrategy.with_callback_user(unquote(Macro.escape(user)))

      conn =
        conn
        |> Plug.Test.init_test_session(%{"oidc_session_params" => %{state: "s"}})
        |> get(~p"/auth/callback/oidc")

      assert redirected_to(conn, 302) == "/"
      assert Plug.Conn.get_session(conn, :user_info) == unquote(Macro.escape(user))
    end
  end

  describe "MeshumWeb.Controllers.Auth.AuthController.logout/2" do
    test "redirects to / and clears the session for a signed-in user", %{conn: conn} do
      conn =
        conn
        |> log_in_user(MeshumWeb.Test.IdpUsers.github())
        |> get(~p"/auth/logout")

      assert redirected_to(conn, 302) == "/"
    end

    test "is safe to call when not signed in", %{conn: conn} do
      conn = get(conn, ~p"/auth/logout")

      assert redirected_to(conn, 302) == "/"
    end
  end

  describe "MeshumWeb.Plugs.Auth.requires_user/2 at the router level" do
    test "redirects unauthenticated requests to /auth/login with a flash", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert redirected_to(conn, 302) == "/auth/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "You must be logged in"
    end

    test "admits authenticated requests through the :auth pipeline", %{conn: conn} do
      conn =
        conn
        |> log_in_user(MeshumWeb.Test.IdpUsers.github())
        |> get(~p"/")

      assert html_response(conn, 200) =~ "Governance overview"
    end
  end
end
