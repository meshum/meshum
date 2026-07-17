defmodule MeshumWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MeshumWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias MeshumWeb.Test.FakeAssentStrategy

  using do
    quote do
      # The default endpoint for testing
      @endpoint MeshumWeb.Endpoint

      use MeshumWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import MeshumWeb.ConnCase
    end
  end

  setup tags do
    Meshum.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Swaps `:auth_providers` to use `MeshumWeb.Test.FakeAssentStrategy` for
  the `:oidc` provider, and restores the previous value when the test
  exits.

  Opt into this from a test module with `setup :setup_fake_oidc`. Tests
  that exercise `MeshumWeb.Auth.Provider` or
  `MeshumWeb.Controllers.Auth.AuthController` should opt in so they don't
  depend on `MeshumWeb.Auth.Oidc` (which makes real HTTP calls to an IdP).
  Tests that don't touch auth don't need it.

  Per-test control of what the fake returns is still done via
  `MeshumWeb.Test.FakeAssentStrategy.with_authorize_url_result/1`,
  `with_callback_result/1`, and `with_callback_user/1`.
  """
  @spec setup_fake_oidc(map()) :: :ok
  def setup_fake_oidc(_context) do
    previous = Application.get_env(:meshum_web, :auth_providers)

    Application.put_env(
      :meshum_web,
      :auth_providers,
      oidc: [
        strategy: FakeAssentStrategy,
        client_id: "test-client-id",
        client_secret: "test-client-secret",
        base_url: "http://idp.test"
      ]
    )

    on_exit(fn ->
      Application.put_env(:meshum_web, :auth_providers, previous)
      FakeAssentStrategy.reset()
    end)

    :ok
  end

  @doc """
  Stages `user` into the test conn's session under the `:user_info` key
  that `MeshumWeb.Plugs.Auth.requires_user/2` reads, simulating a
  signed-in user. Defaults to `MeshumWeb.Test.IdpUsers.github/0` when
  the test doesn't care which IdP the user came from.

  Use this to exercise any route behind the `:auth` pipeline, e.g. the
  control-plane routes gated by `requires_user`:

      %{conn: conn} = setup_conn()
      conn = conn |> log_in_user() |> get(~p"/")
      assert html_response(conn, 200) =~ "Dashboard"

  Tests that need a specific IdP's claim shape should pass one of the
  `MeshumWeb.Test.IdpUsers` fixtures:

      user = MeshumWeb.Test.IdpUsers.entra_id()
      conn = conn |> log_in_user(user) |> get(~p"/")
  """
  @spec log_in_user(Plug.Conn.t(), map() | nil) :: Plug.Conn.t()
  def log_in_user(conn, user \\ MeshumWeb.Test.IdpUsers.github()) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session(:user_info, user)
  end

  @doc """
  Clears any staged user from the test conn's session, simulating a
  signed-out user. The inverse of `log_in_user/2`.
  """
  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.configure_session(drop: true)
  end
end
