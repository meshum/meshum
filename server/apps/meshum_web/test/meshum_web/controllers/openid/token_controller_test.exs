defmodule MeshumWeb.Controllers.Openid.TokenControllerTest do
  use MeshumWeb.ConnCase, async: true

  import Mox

  alias Boruta.Oauth.TokenResponse
  alias MeshumWeb.Controllers.Oauth.TokenController

  setup :verify_on_exit!

  # OIDC reuses the OAuth token endpoint/controller: the id_token is just
  # another field on the same TokenResponse. This exercises the OIDC-shaped
  # (id_token-bearing) response, MeshumWeb.Controllers.Oauth.TokenControllerTest
  # covers the plain OAuth shape.
  describe "MeshumWeb.Controllers.Oauth.TokenController.token/2" do
    test "returns an openid response", %{conn: conn} do
      response = %TokenResponse{
        access_token: "access_token",
        expires_in: 10,
        token_type: "token_type",
        id_token: "id_token",
        refresh_token: "refresh_token"
      }

      Boruta.OauthMock
      |> expect(:token, fn conn, module ->
        module.token_success(conn, response)
      end)

      conn = TokenController.token(conn, %{})

      assert json_response(conn, 200) == %{
               "access_token" => "access_token",
               "id_token" => "id_token",
               "expires_in" => 10,
               "token_type" => "token_type",
               "refresh_token" => "refresh_token"
             }
    end
  end
end
