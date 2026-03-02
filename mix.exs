defmodule Talon.MixProject do
  use Mix.Project

  def project do
    [
      app: :talon,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_core_path: "_priv/plts",
        plt_add_apps: [:mix],
        flags: [:error_handling, :underspecs]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Talon.Application, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:jason, "~> 1.4"},
      {:ex_docker_engine_api, "~> 1.43"},
      {:websockex, "~> 0.5"},
      {:uuid, "~> 1.1"}
    ]
  end
end
