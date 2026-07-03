defmodule MeshumWeb.PageController do
  use MeshumWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
