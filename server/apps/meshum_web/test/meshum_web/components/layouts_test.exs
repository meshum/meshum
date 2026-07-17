defmodule MeshumWeb.LayoutsTest do
  use MeshumWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MeshumWeb.Layouts
  alias MeshumWeb.Test.IdpUsers

  # Parametrized across every realistic IdP user shape. For each shape
  # we render `Layouts.app/1` with `current_user: user` and verify:
  #   - the shell renders without raising
  #   - the sign-out link is present
  #   - the user's `sub` value never leaks into the rendered HTML
  #
  # The pinned expectations in the "display name fallback chain" describe
  # below assert on the exact display name per fixture.
  for {label, user} <- IdpUsers.shapes() do
    describe "MeshumWeb.Layouts.app/1 current_user_card with #{label} shape" do
      setup do
        escaped_user = unquote(Macro.escape(user))

        %{
          html: render_app_shell(escaped_user),
          user: escaped_user
        }
      end

      test "renders without raising and shows a sign-out link", %{html: html} do
        assert html =~ ~s(href="/auth/logout")
        assert html =~ ~s(aria-label="Sign out")
      end

      test "does not leak the sub claim into the rendered HTML", %{
        html: html,
        user: user
      } do
        refute html =~ user["sub"]
      end
    end
  end

  describe "MeshumWeb.Layouts.app/1 without current_user" do
    test "does not render the user card or sign-out link" do
      html = render_app_shell(nil)

      refute html =~ ~s(href="/auth/logout")
      refute html =~ ~s(aria-label="Sign out")
    end

    test "still renders the rest of the shell" do
      html = render_app_shell(nil)

      assert html =~ "Meshum"
      assert html =~ ~s(href="/")
    end
  end

  # Pinned expectations for the `user_display_name/1` fallback chain
  # (name → preferred_username → email → "Signed in"). These are the
  # floor/ceiling tests that catch overfitting to Keycloak's rich claim
  # shape: if a future refactor breaks fallback for sparse shapes (e.g.
  # Entra's no-email case, or the bare-OIDC sub-only case), these fail.
  describe "MeshumWeb.Layouts user_display_name/1 fallback chain" do
    test "prefers 'name' when present (GitHub full)" do
      html = render_app_shell(IdpUsers.github())
      assert html =~ "Wannes Gennar"
    end

    test "falls back to 'preferred_username' when 'name' is absent (GitHub minimal)" do
      html = render_app_shell(IdpUsers.github_minimal())
      assert html =~ "ghost"
    end

    test "renders 'name' for Google (no preferred_username in Google ID tokens)" do
      html = render_app_shell(IdpUsers.google())
      assert html =~ "Alice Example"
    end

    test "renders 'name' for sparse Entra shape (no given_name/family_name)" do
      html = render_app_shell(IdpUsers.entra_id())
      assert html =~ "Alice Example"
    end

    test "renders 'name' even when 'email' is absent (Entra no-email)" do
      html = render_app_shell(IdpUsers.entra_id_no_email())
      assert html =~ "Alice Example"
    end

    test "renders 'name' for Okta (rich shape)" do
      html = render_app_shell(IdpUsers.okta())
      assert html =~ "John Doe"
    end

    test "falls through to 'Signed in' sentinel when no usable name fields are present" do
      html = render_app_shell(IdpUsers.bare_oidc_minimal())
      assert html =~ "Signed in"
    end

    test "prefers 'name' over IdP-specific extras (bare OIDC with extras)" do
      html = render_app_shell(IdpUsers.bare_oidc_with_extras())
      assert html =~ "Wannes Gennar"
    end
  end

  describe "MeshumWeb.Layouts.app/1 sign-out link" do
    test "is present for every IdP shape" do
      for {_label, user} <- IdpUsers.shapes() do
        html = render_app_shell(user)
        assert html =~ ~s(href="/auth/logout")
      end
    end

    test "uses an accessible aria-label" do
      html = render_app_shell(IdpUsers.github())
      assert html =~ ~s(aria-label="Sign out")
    end

    test "includes a descriptive title attribute" do
      html = render_app_shell(IdpUsers.github())
      assert html =~ ~s(title="Sign out")
    end
  end

  # Helper: render the full app shell with a given user. The inner_block
  # is intentionally empty since these tests only care about the
  # surrounding chrome — the user card in particular.
  defp render_app_shell(user) do
    renders =
      render_component(&Layouts.app/1, %{
        flash: %{},
        current_user: user,
        inner_block: [%{inner_block: fn assigns, _ -> ~H"" end}]
      })

    renders
  end
end
