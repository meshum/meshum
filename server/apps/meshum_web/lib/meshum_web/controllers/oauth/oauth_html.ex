defmodule MeshumWeb.Controllers.Oauth.OauthHTML do
  @moduledoc """
  Renders the OAuth/OIDC error page shown when an authorize request fails
  with no `redirect_uri` to bounce the error back to.
  """

  use MeshumWeb, :html

  @doc "Renders the OAuth error description as a simple HTML page."
  def render("error.html", assigns) do
    ~H"""
    <h2>{@error_description}</h2>
    """
  end
end
