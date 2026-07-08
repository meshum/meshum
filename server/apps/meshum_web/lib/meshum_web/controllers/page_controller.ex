defmodule MeshumWeb.PageController do
  @moduledoc """
  Serves the static landing page.
  """
  use MeshumWeb, :controller

  @doc """
  Renders the home page.
  """
  def home(conn, _params) do
    render(conn, :home)
  end
end
