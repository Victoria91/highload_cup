defmodule HighloadCup.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/accounts/new" do
    HighloadCup.new(conn, [])
  end

  get "/accounts/perform" do
    HighloadCup.perform(conn, [])
  end

  post "/accounts/likes" do
    HighloadCup.likes(conn, [])
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

  get "accounts/:id/suggest" do
    HighloadCup.suggest(conn, [])
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
