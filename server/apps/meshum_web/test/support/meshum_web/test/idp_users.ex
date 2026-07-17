defmodule MeshumWeb.Test.IdpUsers do
  @moduledoc """
  Realistic normalized user-map fixtures for the various identity providers
  `MeshumWeb.Controllers.Auth.AuthController` may receive via Assent.

  Each fixture reflects the **post-normalization shape** that production
  code sees after `MeshumWeb.Auth.Oidc` runs `Assent.Strategy.OIDC.Base`'s
  normalization pipeline: standard OIDC claims are type-cast per
  `Assent.Strategy.normalize_userinfo/1`
  (`server/deps/assent/lib/assent/strategy.ex:174`), and any IdP-specific
  extras are deep-merged back on top so they survive.

  ## Why these shapes

  Testing only against a local Keycloak risks overfitting UI and storage
  logic to one IdP's claim shape. The fixtures below capture the meaningful
  differences across GitHub, Google, Microsoft Entra ID, and Okta — and a
  few bare-OIDC stress shapes — so layout fallback chains and session
  roundtrips can be parametrized across all of them.

  Every fixture carries a `@doc` citing its primary source (Assent source
  for GitHub/Google, official IdP docs for Entra/Okta, OIDC Core 1.0 for
  the bare variants). No fixture is fabricated; if a future IdP's shape
  can't be defended from primary sources, it isn't added here.

  ## Usage

  Use `shapes/0` to drive compile-time parametrization in tests:

      for {label, user} <- MeshumWeb.Test.IdpUsers.shapes() do
        describe "MeshumWeb.Layouts with \#{label} shape" do
          test "renders a non-empty display name", do: ...
        end
      end

  Or call individual fixtures directly when the test cares about a specific
  IdP's quirk:

      user = MeshumWeb.Test.IdpUsers.entra_id_no_email()
  """

  @doc """
  A full GitHub user as produced by `Assent.Strategy.Github.normalize/2`.

  **Source:** `server/deps/assent/lib/assent/strategies/github.ex:39-49`,
  cross-referenced with the standard-claims cast table at
  `server/deps/assent/lib/assent/strategy.ex:131-159`. GitHub's `id`
  (integer) is cast to a binary string for `sub`; `email_verified` is a
  real boolean after normalization.

  Fields GitHub populates: `sub`, `name`, `preferred_username`, `profile`,
  `picture`, `email`, `email_verified`. Anything else in GitHub's `/user`
  response (bio, company, followers, etc.) is dropped by `normalize/2` and
  never reaches the user map.
  """
  @spec github() :: map()
  def github do
    %{
      "sub" => "12345678",
      "name" => "Wannes Gennar",
      "preferred_username" => "alloc",
      "profile" => "https://github.com/alloc",
      "picture" => "https://avatars.githubusercontent.com/u/12345678",
      "email" => "alloc@users.noreply.github.com",
      "email_verified" => true
    }
  end

  @doc """
  A GitHub user with no public profile name and an unverified email.

  **Source:** same as `github/0`; demonstrates the realistic edge case at
  `server/deps/assent/lib/assent/strategies/github.ex:74-78` where
  `email` is `nil` and `email_verified` is `false` when the user has no
  primary verified email. After normalization, `name` is **absent** from
  the map entirely (Assent skips nil claim values at
  `server/deps/assent/lib/assent/strategy.ex:198`), so any UI fallback
  chain must handle the missing key — not just `nil`.
  """
  @spec github_minimal() :: map()
  def github_minimal do
    %{
      "sub" => "99999999",
      "preferred_username" => "ghost",
      "profile" => "https://github.com/ghost",
      "picture" => "https://avatars.githubusercontent.com/u/99999999",
      "email" => nil,
      "email_verified" => false
    }
  end

  @doc """
  A Google user via `Assent.Strategy.Google` (which uses
  `Assent.Strategy.OIDC.Base`).

  **Source:** `server/deps/assent/lib/assent/strategies/google.ex:4-7`
  documents the `hd` ("Hosted Domain") extra claim that survives the
  standard-claims cast via deep-merge. The rest of the claims are the
  standard OIDC profile+email set that Google's ID token carries when
  those scopes are requested (`google.ex:34-39`).

  Google's ID tokens never include `preferred_username`; UI fallback
  chains that rely on it must fall through to `email`.
  """
  @spec google() :: map()
  def google do
    %{
      "sub" => "123456789012345678901",
      "name" => "Alice Example",
      "given_name" => "Alice",
      "family_name" => "Example",
      "picture" => "https://lh3.googleusercontent.com/a/ALm5wuExample",
      "email" => "alice@example.com",
      "email_verified" => true,
      "locale" => "en",
      "hd" => "example.com"
    }
  end

  @doc """
  A Microsoft Entra ID (formerly Azure AD) v2.0 user.

  **Source:** Microsoft Learn, "Microsoft Entra ID ID-token claims
  reference" —
  https://learn.microsoft.com/en-us/entra/identity-platform/id-token-claims-reference

  With `openid email profile` scopes and the v2.0 endpoint, Entra emits a
  **sparse** claim set: `name`, `preferred_username`, and `oid` (under
  `profile`), plus `email` (under `email`, when present). It does **not**
  emit `given_name`, `family_name`, `picture`, `email_verified`, or any of
  the other standard profile claims by default — those require optional-
  claims configuration per the application manifest.

  Entra-specific extras (`oid`, `tid`, `ver`, `uti`, `aio`, `rh`) are not
  part of the OIDC standard claims whitelist but are deep-merged back on
  top by `normalize_userinfo/2`, so they reach our code as-is.
  """
  @spec entra_id() :: map()
  def entra_id do
    %{
      "sub" => "AAAAAAAAAAAAAAAAAAAAAIk3qUa9BLpFMc1zAaIX-rA4Q5-K1-Q",
      "oid" => "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb",
      "tid" => "bbbbcccc-1111-2222-3333-dddddddddddd",
      "ver" => "2.0",
      "uti" => "AAnVQ2kLMkFh5fXxH0AAACoH5Q4AA",
      "aio" => "Y2VjAKZ+mcgAUV/TmZkYgxn5asdasdasd==",
      "rh" => "0.AXoAc4Vb5pMasdasdasd.M3lasdasdasd.",
      "name" => "Alice Example",
      "preferred_username" => "alice@contoso.com",
      "email" => "alice@contoso.com"
    }
  end

  @doc """
  An Entra user whose ID token does not carry an `email` claim.

  **Source:** same Microsoft Learn page documents that `email` may be
  absent for guest accounts, personal Microsoft accounts (MSA) without a
  mailbox, or when the `email` optional claim isn't configured. The doc
  explicitly warns: *"This value isn't guaranteed to be correct and is
  mutable over time."*

  Tests UI fallback chains that would otherwise reach for `email`.
  """
  @spec entra_id_no_email() :: map()
  def entra_id_no_email do
    Map.delete(entra_id(), "email")
  end

  @doc """
  An Okta user issued by a default Custom Authorization Server.

  **Source:** Okta developer docs, "OpenID Connect & OAuth 2.0 — ID token
  claims" —
  https://developer.okta.com/docs/api/openapi/okta-oauth/guides/overview/

  Okta emits the **full** standard profile scope (`name`, `nickname`,
  `preferred_username`, `given_name`, `middle_name`, `family_name`,
  `profile`, `zoneinfo`, `locale`, `updated_at`) plus both `email` and
  `email_verified` under the `email` scope — the richest shape of any
  fixture here. `updated_at` and `ver` are integers after normalization.

  Okta-specific extras: `ver` (integer Okta token semantic version),
  `idp` (Okta org ID for direct auth; an IdP ID under federation). The
  Okta base claims `auth_time`, `amr`, `jti` are dropped by Assent's
  ID-token exclusion list (`server/deps/assent/lib/assent/strategies/oidc.ex:302`).
  """
  @spec okta() :: map()
  def okta do
    %{
      "sub" => "00uid4BxXw6I6TV4m0g3",
      "ver" => 1,
      "idp" => "00ok1u7AsAkrwdZL3z0g3",
      "name" => "John Doe",
      "nickname" => "Jimmy",
      "preferred_username" => "john.doe@example.com",
      "given_name" => "John",
      "middle_name" => "James",
      "family_name" => "Doe",
      "profile" => "https://example.com/john.doe",
      "zoneinfo" => "America/Los_Angeles",
      "locale" => "en-US",
      "updated_at" => 1_311_280_970,
      "email" => "john.doe@example.com",
      "email_verified" => true
    }
  end

  @doc """
  The floor of what any OIDC identity provider must return: a single
  `sub` claim.

  **Source:** OpenID Connect Core 1.0, §2 —
  https://openid.net/specs/openid-connect-core-1_0.html#IDToken — `sub`
  is the only end-user claim guaranteed to be present in every ID token.

  Stress-tests UI fallback chains: with no `name`, `preferred_username`,
  or `email`, the display name must fall through to the hardcoded
  "Signed in" sentinel, and the `sub` value must NOT be rendered.
  """
  @spec bare_oidc_minimal() :: map()
  def bare_oidc_minimal do
    %{"sub" => "00000000-0000-0000-0000-000000000000"}
  end

  @doc """
  A bare-OIDC user map (e.g. Keycloak) carrying IdP-specific extras that
  are NOT in the OIDC standard-claims whitelist but survive Assent's
  normalization via the deep-merge of `extra` claims.

  **Source:** the deep-merge contract at
  `server/deps/assent/lib/assent/strategy.ex:236-241`, combined with the
  realistic set of claims Keycloak emits by default (a client's
  `protocolMapper` entries produce `azp`, `session_state`, `realm_access`,
  `resource_access`, etc. — see `containers/keycloak/example-realm-realm.json`).

  Stress-tests that UI display logic ignores non-display extras and does
  not crash when the user map carries deeply-nested structures like
  `realm_access.roles`.
  """
  @spec bare_oidc_with_extras() :: map()
  def bare_oidc_with_extras do
    %{
      "sub" => "f1b8b4a7-3d92-4f7e-9c1a-2b5d8e3f0a1c",
      "name" => "Wannes Gennar",
      "preferred_username" => "wannes",
      "given_name" => "Wannes",
      "family_name" => "Gennar",
      "email" => "wannes@meshum.dev",
      "email_verified" => true,
      "azp" => "meshum",
      "session_state" => "aabbccdd-1122-3344-5566-77889900aabb",
      "sid" => "ccddeeff-2233-4455-6677-889900aabbcc",
      "realm_access" => %{"roles" => ["default-roles-meshum", "user"]},
      "resource_access" => %{
        "meshum" => %{"roles" => ["view-profile", "manage-account"]},
        "account" => %{"roles" => ["manage-account", "view-profile"]}
      }
    }
  end

  @doc """
  Returns `{label, user}` tuples for every fixture in this module, for use
  in compile-time `for` parametrization of `describe` blocks.

  Each label includes the IdP name plus a short disambiguator where the
  module ships more than one variant (e.g. "GitHub (minimal)",
  "Entra ID (no email)"). Labels are stable: tests assert on rendered
  output per shape, so renaming a label here will surface as a test
  failure rather than silently passing.
  """
  @spec shapes() :: [{String.t(), map()}]
  def shapes do
    [
      {"GitHub (full)", github()},
      {"GitHub (minimal)", github_minimal()},
      {"Google", google()},
      {"Entra ID", entra_id()},
      {"Entra ID (no email)", entra_id_no_email()},
      {"Okta", okta()},
      {"Bare OIDC (minimal)", bare_oidc_minimal()},
      {"Bare OIDC (with extras)", bare_oidc_with_extras()}
    ]
  end
end
