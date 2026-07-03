defmodule MeshumGateway.Router do
  use MeshumGateway, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MeshumGateway do
    pipe_through :api
  end
end
