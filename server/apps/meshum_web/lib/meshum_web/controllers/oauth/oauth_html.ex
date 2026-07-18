defmodule MeshumWeb.Controllers.Oauth.OauthHTML do
  use MeshumWeb, :html

  def render("error.html", assigns) do
    ~H"""
    <h2>{@error_description}</h2>
    """
  end
end
