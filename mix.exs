defmodule HighloadCup.MixProject do
  use Mix.Project

  def project do
    [
      app: :highload_cup,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HighloadCup.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:plug, "~> 1.3.4"},
      {:ecto, "~> 2.2.8"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
