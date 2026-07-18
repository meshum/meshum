defmodule MeshumWeb.Auth.UserTest do
  use ExUnit.Case, async: true

  alias MeshumWeb.Auth.User
  alias MeshumWeb.Test.IdpUsers

  describe "MeshumWeb.Auth.User.from_claims/2" do
    test "raises when the claims map has no 'sub'" do
      assert_raise KeyError, fn -> User.from_claims(%{"email" => "a@b.test"}) end
    end

    test "defaults authenticated_at to nil when not given" do
      user = User.from_claims(IdpUsers.github())

      assert user.authenticated_at == nil
    end

    test "carries the given authenticated_at through untouched" do
      authenticated_at = DateTime.utc_now()
      user = User.from_claims(IdpUsers.github(), authenticated_at)

      assert user.authenticated_at == authenticated_at
    end

    test "keeps the full raw claims map reachable via :claims" do
      claims = IdpUsers.bare_oidc_with_extras()
      user = User.from_claims(claims)

      assert user.claims == claims
    end
  end

  # Parametrized across every realistic IdP user shape (see `IdpUsers` for
  # the documented variance): `sub` is the only claim guaranteed present, so
  # it's the only field asserted unconditionally here. `email`/`display_name`
  # are asserted per-shape below since their presence genuinely varies.
  for {label, claims} <- IdpUsers.shapes() do
    describe "MeshumWeb.Auth.User.from_claims/2 with #{label} shape" do
      test "sub is always the claims' 'sub'" do
        claims = unquote(Macro.escape(claims))
        assert User.from_claims(claims).sub == claims["sub"]
      end

      test "email mirrors the claims' 'email', nil when absent or unset" do
        claims = unquote(Macro.escape(claims))
        assert User.from_claims(claims).email == claims["email"]
      end
    end
  end

  describe "MeshumWeb.Auth.User.from_claims/2 display_name fallback chain" do
    test "prefers 'name' when present" do
      assert User.from_claims(IdpUsers.github()).display_name == "Wannes Gennar"
    end

    test "falls back to 'preferred_username' when 'name' is absent" do
      assert User.from_claims(IdpUsers.github_minimal()).display_name == "ghost"
    end

    test "falls back to 'email' when neither 'name' nor 'preferred_username' is present" do
      claims = IdpUsers.bare_oidc_minimal() |> Map.put("email", "sub-only@example.com")

      assert User.from_claims(claims).display_name == "sub-only@example.com"
    end

    test "is nil when name, preferred_username, and email are all absent" do
      assert User.from_claims(IdpUsers.bare_oidc_minimal()).display_name == nil
    end

    test "never falls back to sub" do
      user = User.from_claims(IdpUsers.bare_oidc_minimal())

      refute user.display_name == user.sub
    end
  end

  describe "MeshumWeb.Auth.User.to_resource_owner/1" do
    test "maps sub, email, and authenticated_at onto the ResourceOwner" do
      authenticated_at = DateTime.utc_now()
      user = User.from_claims(IdpUsers.github(), authenticated_at)

      assert User.to_resource_owner(user) == %Boruta.Oauth.ResourceOwner{
               sub: user.sub,
               username: user.email,
               last_login_at: authenticated_at
             }
    end

    test "username is nil when the user has no email", %{} do
      user = User.from_claims(IdpUsers.entra_id_no_email())

      assert User.to_resource_owner(user).username == nil
    end
  end
end
