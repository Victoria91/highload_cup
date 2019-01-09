defmodule HighloadCup.Repo do
  use Ecto.Repo,
    otp_app: :highload_cup,
    adapter: Ecto.Adapters.Postgres
end
