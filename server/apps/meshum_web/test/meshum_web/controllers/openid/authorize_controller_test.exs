defmodule MeshumWeb.Controllers.Openid.AuthorizeControllerTest do
  use MeshumWeb.ConnCase, async: true

  import Mox

  alias Boruta.Oauth.AuthorizeResponse
  alias Boruta.Oauth.Error
  alias MeshumWeb.Auth.User
  alias MeshumWeb.Controllers.Openid.AuthorizeController

  setup :verify_on_exit!

  setup %{conn: conn} do
    conn =
      %{conn | query_params: %{}}
      |> init_test_session(%{})

    {:ok, conn: conn}
  end

  describe "MeshumWeb.Controllers.Openid.AuthorizeController.authorize/2" do
    test "redirects_to login if prompt=login", %{conn: conn} do
      conn = %{conn | query_params: %{"prompt" => "login"}}

      assert_authorize_user_logged_out(conn)
    end

    test "redirects_to an error if prompt=none and user not logged in", %{conn: conn} do
      conn = %{conn | query_params: %{"prompt" => "none"}}

      error = %Error{
        status: :unauthorized,
        error: :login_required,
        error_description: "Error description",
        format: :fragment
      }

      Boruta.OauthMock
      |> expect(:authorize, fn conn, _resource_owner, module ->
        module.authorize_error(conn, error)
      end)

      conn = AuthorizeController.authorize(conn, %{})

      assert redirected_to(conn) =~ ~r/error=login_required/
    end

    test "redirects to user login when user not logged in", %{conn: conn} do
      assert_authorize_redirected_to_login(conn)
    end
  end

  # Parametrized across every realistic IdP user shape, normalized through
  # `User.from_claims/1` exactly as `MeshumWeb.Plugs.Auth.fetch_current_user/2`
  # does in production — never a hand-written `%User{}` fixture, so these
  # tests can't silently drift from what production actually builds.
  for {label, user} <- MeshumWeb.Test.IdpUsers.shapes() do
    describe "MeshumWeb.Controllers.Openid.AuthorizeController.authorize/2 with #{label} shape" do
      test "redirects_to login if user is invalid", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        error = %Error{
          status: :unauthorized,
          error: :invalid_resource_owner,
          error_description: "Error description",
          format: :query
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_error(conn, error)
        end)

        assert_authorize_redirected_to_login(conn)
      end

      test "redirects to login if user is logged in and max age is expired", %{conn: conn} do
        current_user = User.from_claims(unquote(Macro.escape(user)), DateTime.utc_now())
        conn = assign(conn, :current_user, current_user)
        conn = %{conn | query_params: %{"max_age" => "0"}}

        assert_authorize_user_logged_out(conn)
      end

      test "authorizes if user is logged in and max age is not expired", %{conn: conn} do
        current_user = User.from_claims(unquote(Macro.escape(user)), DateTime.utc_now())
        conn = assign(conn, :current_user, current_user)
        conn = %{conn | query_params: %{"max_age" => "10"}}

        response = %AuthorizeResponse{
          type: :token,
          redirect_uri: "http://redirect.uri",
          access_token: "access_token",
          expires_in: 10
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_success(conn, response)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri#access_token=access_token&expires_in=10"
      end

      test "returns an error page", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        error = %Error{
          status: :bad_request,
          error: :unknown_error,
          error_description: "Error description"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_error(conn, error)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert html_response(conn, 400) =~ ~r/Error description/
      end

      test "returns an error in fragment", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        error = %Error{
          status: :bad_request,
          error: :unknown_error,
          error_description: "Error description",
          format: :fragment,
          redirect_uri: "http://redirect.uri"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_error(conn, error)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri#error=unknown_error&error_description=Error+description"
      end

      test "returns an error in query", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        error = %Error{
          status: :bad_request,
          error: :unknown_error,
          error_description: "Error description",
          format: :query,
          redirect_uri: "http://redirect.uri"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_error(conn, error)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri?error=unknown_error&error_description=Error+description"
      end

      test "redirects with an access_token", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        response = %AuthorizeResponse{
          type: :token,
          redirect_uri: "http://redirect.uri",
          access_token: "access_token",
          expires_in: 10
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_success(conn, response)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri#access_token=access_token&expires_in=10"
      end

      test "redirects with an access_token and a state", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        response = %AuthorizeResponse{
          type: :token,
          redirect_uri: "http://redirect.uri",
          access_token: "access_token",
          expires_in: 10,
          state: "state"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_success(conn, response)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        %URI{fragment: fragment} = URI.parse(redirected_to(conn))

        assert URI.decode_query(fragment) == %{
                 "access_token" => "access_token",
                 "expires_in" => "10",
                 "state" => "state"
               }
      end

      test "redirects with an code", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        response = %AuthorizeResponse{
          type: :code,
          redirect_uri: "http://redirect.uri",
          code: "code"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_success(conn, response)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri?code=code"
      end

      test "redirects with an code and a state", %{conn: conn} do
        conn = assign(conn, :current_user, unquote(Macro.escape(User.from_claims(user))))

        response = %AuthorizeResponse{
          type: :code,
          redirect_uri: "http://redirect.uri",
          code: "code",
          state: "state"
        }

        Boruta.OauthMock
        |> expect(:authorize, fn conn, _resource_owner, module ->
          module.authorize_success(conn, response)
        end)

        conn = AuthorizeController.authorize(conn, %{})

        assert redirected_to(conn) ==
                 "http://redirect.uri?code=code&state=state"
      end
    end
  end

  defp assert_authorize_redirected_to_login(conn) do
    assert_raise RuntimeError,
                 """
                 Here occurs the login process. After login, user may be redirected to
                 get_session(conn, :user_return_to)
                 """,
                 fn ->
                   AuthorizeController.authorize(conn, %{})
                 end
  end

  defp assert_authorize_user_logged_out(conn) do
    assert_raise RuntimeError,
                 """
                 Here user shall be logged out then redirected to login. After login, user may be redirected to
                 get_session(conn, :user_return_to)
                 """,
                 fn ->
                   AuthorizeController.authorize(conn, %{})
                 end
  end
end
