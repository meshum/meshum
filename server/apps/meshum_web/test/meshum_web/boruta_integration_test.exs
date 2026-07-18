defmodule MeshumWeb.BorutaIntegrationTest do
  @moduledoc """
  Every other Boruta-facing test in this app mocks `Boruta.Oauth`/
  `Boruta.Openid` (via `Boruta.OauthMock`/`Boruta.OpenidMock`), so none of
  them ever exercise the real library — including `config :boruta,
  Boruta.Oauth, repo: ...`, which `Boruta.Config.repo/0` requires via
  `Keyword.fetch!` and would raise without. This test drives the real,
  unmocked `Boruta.Oauth` through the actual `/oauth/token` HTTP endpoint, so
  a missing/wrong Boruta config fails this test, not just a production
  crash nobody caught in CI.

  It flips the global `:meshum_web, :oauth_module` app env to the real
  `Boruta.Oauth` (every other test relies on it being the Mox mock), so this
  module is `async: false`. Note: ExUnit's docs do not formally guarantee
  that an `async: false` module is fully isolated from concurrently-running
  `async: true` modules (only that `async: true` modules run concurrently
  with each other) — this is a known, accepted gap, not a verified
  guarantee.
  """

  use MeshumWeb.ConnCase, async: false

  setup do
    previous_oauth_module = Application.get_env(:meshum_web, :oauth_module)
    Application.put_env(:meshum_web, :oauth_module, Boruta.Oauth)

    on_exit(fn ->
      Application.put_env(:meshum_web, :oauth_module, previous_oauth_module)
    end)
  end

  describe "POST /oauth/token (real Boruta.Oauth, not mocked)" do
    test "issues an access token for a client_credentials grant", %{conn: conn} do
      {:ok, client} =
        Boruta.Ecto.Admin.Clients.create_client(%{redirect_uris: ["https://example.com"]})

      conn =
        post(conn, ~p"/oauth/token", %{
          "grant_type" => "client_credentials",
          "client_id" => client.id,
          "client_secret" => client.secret
        })

      assert %{"access_token" => access_token, "token_type" => "bearer"} =
               json_response(conn, 200)

      assert is_binary(access_token)
    end
  end
end
