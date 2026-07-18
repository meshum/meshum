defmodule MeshumWeb.Controllers.Openid.OpenidJSON do
  @moduledoc """
  Renders the OIDC JWKS and userinfo endpoint responses as JSON.
  """

  alias Boruta.Openid.UserinfoResponse

  @doc """
  Renders `"jwks.json"` (the JWKS document) or `"userinfo.json"` (the
  requesting user's claims, via `UserinfoResponse.payload/1`).
  """
  def render("jwks.json", %{jwk_keys: jwk_keys}) do
    %{keys: jwk_keys}
  end

  def render("userinfo.json", %{response: response}) do
    UserinfoResponse.payload(response)
  end
end
