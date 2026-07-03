defmodule Meshum.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Meshum.Repo,
      {DNSCluster, query: Application.get_env(:meshum, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Meshum.PubSub}
      # Start a worker by calling: Meshum.Worker.start_link(arg)
      # {Meshum.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Meshum.Supervisor)
  end
end
