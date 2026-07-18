defmodule MeshumWeb.Controllers.Openid.JwksController do
  @behaviour Boruta.Openid.JwksApplication

  use MeshumWeb, :controller

  alias MeshumWeb.Controllers.Openid.OpenidJSON

  @doc "The `Boruta.Openid` implementation to dispatch to; overridden in tests via Mox."
  def openid_module, do: Application.get_env(:meshum_web, :openid_module, Boruta.Openid)

  def jwks_index(conn, _params) do
    openid_module().jwks(conn, __MODULE__)
  end

  @impl Boruta.Openid.JwksApplication
  def jwk_list(conn, jwk_keys) do
    conn
    |> put_view(OpenidJSON)
    |> render("jwks.json", jwk_keys: jwk_keys)
  end
end
