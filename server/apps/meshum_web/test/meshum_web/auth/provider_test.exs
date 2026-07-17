defmodule MeshumWeb.Auth.ProviderTest do
  use MeshumWeb.ConnCase

  alias MeshumWeb.Auth.Provider
  alias MeshumWeb.Test.FakeAssentStrategy

  describe "MeshumWeb.Auth.Provider.to_provider/1" do
    test "accepts the 'oidc' provider name" do
      assert Provider.to_provider("oidc") == {:ok, :oidc}
    end

    test "rejects unknown provider names" do
      assert Provider.to_provider("github") == {:error, :unknown_provider}
      assert Provider.to_provider("saml") == {:error, :unknown_provider}
    end

    test "rejects nil and empty input" do
      assert Provider.to_provider(nil) == {:error, :unknown_provider}
      assert Provider.to_provider("") == {:error, :unknown_provider}
    end
  end

  describe "MeshumWeb.Auth.Provider.configured/0" do
    test "lists the keys configured under :auth_providers" do
      swap_auth_providers(oidc: [strategy: FakeAssentStrategy, base_url: "http://x"])

      assert Provider.configured() == [:oidc]
    end

    test "returns [] when :auth_providers is an empty keyword list" do
      swap_auth_providers([])

      assert Provider.configured() == []
    end

    test "returns [] when :auth_providers is unset" do
      swap_auth_providers(nil)

      assert Provider.configured() == []
    end
  end

  describe "MeshumWeb.Auth.Provider.authorize_url/1" do
    setup :setup_fake_oidc

    test "delegates to the configured strategy and returns its result" do
      expected = {:ok, %{url: "https://idp.test/auth", session_params: %{state: "abc"}}}
      FakeAssentStrategy.with_authorize_url_result(expected)

      assert Provider.authorize_url(:oidc) == expected
    end

    test "forwards errors from the strategy verbatim" do
      FakeAssentStrategy.with_authorize_url_result({:error, :no_openid_configuration})

      assert Provider.authorize_url(:oidc) == {:error, :no_openid_configuration}
    end

    test "injects :redirect_uri based on the callback route and endpoint url" do
      FakeAssentStrategy.with_authorize_url_result({:ok, %{url: "u", session_params: %{}}})

      {:ok, _} = Provider.authorize_url(:oidc)

      assert FakeAssentStrategy.last_authorize_url_config()[:redirect_uri] ==
               MeshumWeb.Endpoint.url() <> "/auth/callback/oidc"
    end

    test "passes the configured client_id, client_secret, base_url, and strategy through" do
      FakeAssentStrategy.with_authorize_url_result({:ok, %{url: "u", session_params: %{}}})

      {:ok, _} = Provider.authorize_url(:oidc)

      config = FakeAssentStrategy.last_authorize_url_config()
      assert config[:strategy] == FakeAssentStrategy
      assert config[:client_id] == "test-client-id"
      assert config[:client_secret] == "test-client-secret"
      assert config[:base_url] == "http://idp.test"
    end

    test "raises RuntimeError when the provider is not configured" do
      swap_auth_providers([])

      assert_raise RuntimeError, ~r/No provider configuration for oidc/, fn ->
        Provider.authorize_url(:oidc)
      end
    end
  end

  describe "MeshumWeb.Auth.Provider.callback/3" do
    setup :setup_fake_oidc

    test "delegates to the configured strategy and returns its result" do
      user = MeshumWeb.Test.IdpUsers.github()
      FakeAssentStrategy.with_callback_user(user)

      assert {:ok, %{user: ^user}} =
               Provider.callback(:oidc, %{"code" => "abc"}, %{state: "xyz"})
    end

    test "forwards errors from the strategy verbatim" do
      FakeAssentStrategy.with_callback_result({:error, :invalid_state})

      assert Provider.callback(:oidc, %{"code" => "abc"}, %{state: "xyz"}) ==
               {:error, :invalid_state}
    end

    test "passes session_params to the strategy under the :session_params key" do
      FakeAssentStrategy.with_callback_user(MeshumWeb.Test.IdpUsers.github())
      session_params = %{state: "the-state", code_verifier: "the-verifier"}

      {:ok, _} = Provider.callback(:oidc, %{"code" => "abc"}, session_params)

      assert FakeAssentStrategy.last_callback_config()[:session_params] == session_params
    end

    test "passes the callback request params to the strategy" do
      FakeAssentStrategy.with_callback_user(MeshumWeb.Test.IdpUsers.github())
      params = %{"code" => "abc", "state" => "xyz"}

      {:ok, _} = Provider.callback(:oidc, params, %{})

      assert FakeAssentStrategy.last_callback_params() == params
    end

    test "injects :redirect_uri into the strategy config" do
      FakeAssentStrategy.with_callback_user(MeshumWeb.Test.IdpUsers.github())

      {:ok, _} = Provider.callback(:oidc, %{"code" => "abc"}, %{})

      assert FakeAssentStrategy.last_callback_config()[:redirect_uri] ==
               MeshumWeb.Endpoint.url() <> "/auth/callback/oidc"
    end

    test "raises RuntimeError when the provider is not configured" do
      swap_auth_providers([])

      assert_raise RuntimeError, ~r/No provider configuration for oidc/, fn ->
        Provider.callback(:oidc, %{}, %{})
      end
    end
  end

  describe "MeshumWeb.Auth.Oidc wrapper" do
    # Verifies that `MeshumWeb.Auth.Oidc` is wired up as a valid
    # `Assent.Strategy.OIDC.Base` strategy. The full end-to-end flow
    # (including normalization and HTTP calls to an IdP) is left to a
    # future Bypass-based integration test.

    test "implements the Assent.Strategy.OIDC.Base contract" do
      Code.ensure_loaded!(MeshumWeb.Auth.Oidc)

      assert function_exported?(MeshumWeb.Auth.Oidc, :default_config, 1)
      assert function_exported?(MeshumWeb.Auth.Oidc, :authorize_url, 1)
      assert function_exported?(MeshumWeb.Auth.Oidc, :callback, 2)
      assert function_exported?(MeshumWeb.Auth.Oidc, :normalize, 2)

      assert MeshumWeb.Auth.Oidc.default_config([]) == []
    end

    test "Provider.configured/0 surfaces it when wired as the :oidc strategy" do
      swap_auth_providers(
        oidc: [
          strategy: MeshumWeb.Auth.Oidc,
          client_id: "x",
          client_secret: "y",
          base_url: "http://idp.test"
        ]
      )

      assert Provider.configured() == [:oidc]
    end
  end

  # Swaps `:auth_providers` for the duration of a single test, restoring
  # the previous value on exit. Passing `nil` deletes the env entry
  # entirely (simulating "no auth_providers config at all").
  defp swap_auth_providers(config) do
    previous = Application.get_env(:meshum_web, :auth_providers)

    if config do
      Application.put_env(:meshum_web, :auth_providers, config)
    else
      Application.delete_env(:meshum_web, :auth_providers)
    end

    on_exit(fn ->
      if previous do
        Application.put_env(:meshum_web, :auth_providers, previous)
      else
        Application.delete_env(:meshum_web, :auth_providers)
      end
    end)
  end
end
