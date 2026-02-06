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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.21.0"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:jason, "~> 1.4.4"}
    ]
  end
end
