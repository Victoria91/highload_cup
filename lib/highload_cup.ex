defmodule HighloadCup do
  import Plug.Conn
  use Plug.Builder

  alias HighloadCup.Models.Account
  alias HighloadCup.{SearchService, GroupService, RecommendService, Repo}
  # plug Plug.Parsers, parsers: [:json],
  # pass:  ["text/*"],
  # json_decoder: Poison

  def init(options), do: options

  def call(conn, opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!\n")
  end

  def new(conn, opts) do
    IO.inspect("NEW+++++++++++")
    {:ok, body, conn} = read_body(conn, opts)
    {:ok, decoded_body} = body |> Poison.decode() |> IO.inspect()

    case Account.insert(decoded_body) |> IO.inspect() do
      {:ok, account} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, "{}")

      _ ->
        conn
        |> send_resp(400, "")
    end
  end

  def update(%{path_params: %{"id" => id}} = conn, opts) do
    IO.inspect("NEW+++++++++++")
    # with %Account = Repo.get(Account, id) do
    {:ok, body, conn} = read_body(conn, opts)
    {:ok, decoded_body} = body |> Poison.decode() |> IO.inspect()

    case Account.update(id, decoded_body) do
      {:ok, account} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(202, "{}")

      {:error, :not_found} ->
        conn
        |> send_resp(404, "")

      _ ->
        conn
        |> send_resp(400, "")
    end
  end

  def filter(conn, opts) do
    # {:ok, body, conn} = read_body(conn, opts) 
    Plug.Conn.Query.decode(conn.query_string) |> SearchService.perform() |> IO.inspect()
    # {:ok, decoded_body} = body |> Poison.decode |>  IO.inspect

    # HighloadCup.Repo.all(Account) |> IO.inspect

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello filter!\n")
  end

  def group(conn, opts) do
    res = Plug.Conn.Query.decode(conn.query_string) |> GroupService.perform() |> IO.inspect()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, %{groups: res} |> Poison.encode!() |> IO.inspect())
  end

  def recommend(%{path_params: %{"id" => id}} = conn, _opts) do
    case Repo.get(Account, id) do
      %Account{} = account ->
        Plug.Conn.Query.decode(conn.query_string) |> RecommendService.perform(account)
        |> IO.inspect()

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, "Hello recommend!\n")

      _ ->
        conn
        |> send_resp(404, "")
    end
  end
end
