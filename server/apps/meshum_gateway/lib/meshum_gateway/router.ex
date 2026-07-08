defmodule MeshumGateway.Router do
  @moduledoc """
  Routes for the MCP proxy gateway API.
  """
  use MeshumGateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MeshumGateway do
    pipe_through :api
  end
end
