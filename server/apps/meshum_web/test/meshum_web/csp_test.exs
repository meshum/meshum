defmodule MeshumWeb.Plugs.CspTest do
  use MeshumWeb.ConnCase, async: true

  alias MeshumWeb.Plugs.Csp

  describe "MeshumWeb.Plugs.Csp.generate_nonce/0" do
    test "returns a base64-encoded value" do
      nonce = Csp.generate_nonce()
      assert {:ok, _} = Base.decode64(nonce)
    end

    test "returns a distinct value each call" do
      refute Csp.generate_nonce() == Csp.generate_nonce()
    end
  end

  describe "MeshumWeb.Plugs.Csp.policy/1" do
    test "allow-lists the given nonce for scripts, but not inline scripts" do
      policy = Csp.policy("test-nonce")
      assert policy =~ "script-src 'self' 'nonce-test-nonce'"
      refute policy =~ "script-src 'self' 'unsafe-inline'"
    end

    test "permits data: images (heroicons) and self-hosted fonts" do
      policy = Csp.policy("n")
      assert policy =~ "img-src 'self' data:"
      assert policy =~ "font-src 'self'"
    end

    test "restricts everything to same-origin by default and hardens base/object" do
      policy = Csp.policy("n")
      assert policy =~ "default-src 'self'"
      assert policy =~ "base-uri 'self'"
      assert policy =~ "object-src 'none'"
      assert policy =~ "frame-ancestors 'self'"
    end
  end

  describe "MeshumWeb.Plugs.Csp.call/2" do
    test "sets the CSP header and assigns a matching nonce", %{conn: conn} do
      conn = Csp.call(conn, [])

      nonce = conn.assigns.csp_nonce
      assert [header] = get_resp_header(conn, "content-security-policy")
      assert header =~ "'nonce-#{nonce}'"
    end
  end

  describe "the :browser pipeline" do
    test "emits a CSP header whose nonce matches the inline script", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert [header] = get_resp_header(conn, "content-security-policy")
      assert [_, nonce] = Regex.run(~r/'nonce-([^']+)'/, header)
      assert html =~ ~s(<script nonce="#{nonce}">)
    end
  end
end
