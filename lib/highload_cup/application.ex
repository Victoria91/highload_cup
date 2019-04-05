defmodule HighloadCup.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: HighloadCup.Router,
        options: [port: 80]
      ),
      {HighloadCup.Repo, []}
    ]
    Logger.remove_backend(:console)

    IO.inspect Application.get_env(:highload_cup, :time)[:current_time], label: "current_time"
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
