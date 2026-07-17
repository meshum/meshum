defmodule MeshumWeb.PageController do
  @moduledoc """
  Serves the static landing page.
  """
  use MeshumWeb, :controller

  alias MeshumWeb.Layouts

  @doc """
  Renders the dashboard (the `/` landing page).
  """
  def home(conn, _params) do
    render(conn, :home)
  end

  @doc """
  Renders a stub for a nav section whose screens aren't built yet, so the
  shell and navigation are usable end-to-end. The section is resolved from
  the request path against `Layouts.nav_items/0`.
  """
  def section(conn, _params) do
    section = Enum.find(Layouts.nav_items(), &(&1.path == conn.request_path))
    render(conn, :placeholder, section: section)
  end
end
