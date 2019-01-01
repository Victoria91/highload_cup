defmodule HighloadCup.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, HighloadCup, [], port: 8080),
      {HighloadCup.Repo, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
