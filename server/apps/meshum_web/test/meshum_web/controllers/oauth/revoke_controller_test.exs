defmodule MeshumWeb.Controllers.Oauth.RevokeControllerTest do
  use MeshumWeb.ConnCase, async: true

  import Mox

  alias Boruta.Oauth.Error
  alias MeshumWeb.Controllers.Oauth.RevokeController

  setup :verify_on_exit!

  describe "MeshumWeb.Controllers.Oauth.RevokeController.revoke/2" do
    test "returns an oauth error", %{conn: conn} do
      error = %Error{
        status: :bad_request,
        error: :unknown_error,
        error_description: "Error description"
      }

      Boruta.OauthMock
      |> expect(:revoke, fn conn, module ->
        module.revoke_error(conn, error)
      end)

      conn = RevokeController.revoke(conn, %{})

      assert json_response(conn, 400) == %{
               "error" => "unknown_error",
               "error_description" => "Error description"
             }
    end

    test "respond 200", %{conn: conn} do
      Boruta.OauthMock
      |> expect(:revoke, fn conn, module ->
        module.revoke_success(conn)
      end)

      conn = RevokeController.revoke(conn, %{})

      assert response(conn, 200)
    end
  end
end
