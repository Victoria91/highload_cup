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
      {:plug_cowboy, "~> 2.0"},
      {:ecto, "~> 2.2.8"},
      {:postgrex, ">= 0.0.0"},
      {:poison, "~> 3.1"}
    ]
  end
end
