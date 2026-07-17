defmodule MeshumWeb.Plugs.Csp do
  @moduledoc """
  Content Security Policy for the control plane.

  Used as a plug in the `:browser` pipeline. On each request it generates a
  fresh nonce, exposes it as `conn.assigns.csp_nonce`, and sets a
  `content-security-policy` header that allow-lists that nonce for inline
  scripts. The root layout's theme-bootstrap `<script>` carries
  `nonce={@csp_nonce}`, so it runs without opening the policy up to
  `'unsafe-inline'` scripts.

  The policy is deliberately strict — everything is same-origin (`'self'`)
  except:

    * **`script-src`** additionally allows the per-request `'nonce-…'`. This
      covers the single inline theme script in the root layout; every other
      script must be a bundled, same-origin file (`app.js`).
    * **`img-src`** additionally allows `data:`. The Tailwind heroicons plugin
      renders each `hero-*` icon from an inlined `data:` SVG URI.
    * **`style-src`** additionally allows `'unsafe-inline'`. Inline `style`
      attributes and injected `<style>` blocks (Tailwind, LiveView
      transitions) cannot carry a nonce; style injection is low-risk next to
      script injection.

  Same-origin websockets (the LiveView socket) are covered by
  `connect-src 'self'`.
  """
  import Plug.Conn

  # Random bytes backing each nonce; base64-encoded into the header.
  @nonce_bytes 18

  @doc false
  def init(opts), do: opts

  @doc """
  Assigns a fresh `:csp_nonce` and sets the `content-security-policy` header.
  """
  def call(conn, _opts) do
    nonce = generate_nonce()

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy(nonce))
  end

  @doc """
  Generates a base64-encoded CSP nonce from cryptographically strong bytes.
  """
  def generate_nonce do
    @nonce_bytes |> :crypto.strong_rand_bytes() |> Base.encode64()
  end

  @doc """
  Builds the CSP header value, allow-listing `nonce` for inline scripts.
  """
  def policy(nonce) do
    [
      {"default-src", ~w('self')},
      {"script-src", ["'self'", "'nonce-#{nonce}'"]},
      {"style-src", ~w('self' 'unsafe-inline')},
      {"img-src", ~w('self' data:)},
      {"font-src", ~w('self')},
      {"connect-src", ~w('self')},
      {"base-uri", ~w('self')},
      {"form-action", ~w('self')},
      {"frame-ancestors", ~w('self')},
      {"object-src", ~w('none')}
    ]
    |> Enum.map_join("; ", fn {directive, sources} ->
      directive <> " " <> Enum.join(sources, " ")
    end)
  end
end
