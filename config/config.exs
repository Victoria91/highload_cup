# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :highload_cup, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:highload_cup, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :highload_cup, ecto_repos: [HighloadCup.Repo]

config :highload_cup, :time,
  current_time:
    (try do
       File.read!('/tmp/data/options.txt') |> String.split("\n") |> List.first()
       |> String.to_integer()
     rescue
       _ -> nil
     end)

config :highload_cup, HighloadCup.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "highload_cup",
  hostname: "localhost",
  pool_size: 10,
  timeout: 15_000,
  ownership_timeout: 15_000
