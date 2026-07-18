defmodule MeshumWeb.Controllers.Oauth.TokenControllerTest do
  use MeshumWeb.ConnCase, async: true

  import Mox

  alias Boruta.Oauth.Error
  alias Boruta.Oauth.TokenResponse
  alias MeshumWeb.Controllers.Oauth.TokenController

  setup :verify_on_exit!

  describe "MeshumWeb.Controllers.Oauth.TokenController.token/2" do
    test "returns an oauth error", %{conn: conn} do
      error = %Error{
        status: :bad_request,
        error: :unknown_error,
        error_description: "Error description"
      }

      Boruta.OauthMock
      |> expect(:token, fn conn, module ->
        module.token_error(conn, error)
      end)

      conn = TokenController.token(conn, %{})

      assert json_response(conn, 400) == %{
               "error" => "unknown_error",
               "error_description" => "Error description"
             }
    end

    test "returns an oauth response", %{conn: conn} do
      response = %TokenResponse{
        access_token: "access_token",
        expires_in: 10,
        token_type: "token_type",
        refresh_token: "refresh_token"
      }

      Boruta.OauthMock
      |> expect(:token, fn conn, module ->
        module.token_success(conn, response)
      end)

      conn = TokenController.token(conn, %{})

      assert json_response(conn, 200) == %{
               "access_token" => "access_token",
               "expires_in" => 10,
               "token_type" => "token_type",
               "refresh_token" => "refresh_token"
             }
    end
  end
end
