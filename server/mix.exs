defmodule Meshum.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      name: "meshum_umbrella",
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader],
      releases: releases()
    ]
  end

  # Umbrella projects must define their releases explicitly; the release
  # version is inherited from the umbrella project version above.
  defp releases do
    [
      meshum_gateway: [
        applications: [meshum_gateway: :permanent]
      ],
      meshum_web: [
        applications: [meshum_web: :permanent]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    [
      # Required to run "mix format" on ~H/.heex files from the umbrella root
      {:phoenix_live_view, ">= 0.0.0"},
      {:ex_check, "~> 0.14.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
