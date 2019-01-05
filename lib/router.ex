defmodule HighloadCup.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/accounts/new" do
    HighloadCup.new(conn, [])
  end

  post "/accounts/:id" do
    HighloadCup.update(conn, [])
  end

  get "accounts/filter" do
    HighloadCup.filter(conn, [])
  end

  get "accounts/group" do
    HighloadCup.group(conn, [])
  end

  get "accounts/:id/recommend" do
    HighloadCup.recommend(conn, [])
  end

  # forward "/users", to: UsersRouter

  match _ do
    send_resp(conn, 404, "oops")
  end
end
