defmodule MeshumWeb.Controllers.Auth.AuthHTMLTest do
  use MeshumWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MeshumWeb.Controllers.Auth.AuthHTML

  # `AuthHTML.login/1` reads `MeshumWeb.Auth.Provider.configured/0`, which
  # reflects the `:auth_providers` env. The fake strategy is wired in for
  # every test so the rendered output is deterministic.
  setup :setup_fake_oidc

  describe "MeshumWeb.Controllers.Auth.AuthHTML.login/1" do
    test "renders one sign-in link per configured provider" do
      html = render_component(&AuthHTML.login/1, %{})

      assert html =~ ~s(href="/auth/login/oidc")
      assert html =~ "Continue with oidc"
    end

    test "renders the heading and explanatory copy" do
      html = render_component(&AuthHTML.login/1, %{})

      assert html =~ "Sign in to Meshum"
      assert html =~ "Authenticate with your organization's identity provider"
    end

    test "renders no sign-in links when no providers are configured" do
      swap_auth_providers([])
      html = render_component(&AuthHTML.login/1, %{})

      refute html =~ ~s(href="/auth/login/)
    end
  end

  describe "MeshumWeb.Controllers.Auth.AuthHTML.error/1" do
    test "renders the failure copy" do
      html = render_component(&AuthHTML.error/1, %{})

      assert html =~ "Something went wrong during sign-in"
    end

    test "renders a back-to-login link" do
      html = render_component(&AuthHTML.error/1, %{})

      assert html =~ ~s(href="/auth/login")
      assert html =~ "Back to login"
    end
  end

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
