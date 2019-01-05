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
    params = Plug.Conn.Query.decode(conn.query_string) |> IO.inspect()

    case SearchService.perform(params) do
      :error ->
        conn
        |> send_resp(400, "err")

      result ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, %{accounts: result} |> Poison.encode!())
    end
  end

  def group(conn, opts) do
    params = Plug.Conn.Query.decode(conn.query_string) |> IO.inspect()

    case validate_params(params) do
      :error ->
        conn
        |> send_resp(400, "err")

      _ ->
        res = GroupService.perform(params)

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, %{groups: res} |> Poison.encode!() |> IO.inspect())
    end
  end

  def recommend(%{path_params: %{"id" => id}} = conn, _opts) do
    decoded_params = Plug.Conn.Query.decode(conn.query_string)

    with %{} = params <- validate_params(decoded_params),
         %Account{} = account <- Repo.get(Account, id) do
      result = RecommendService.perform(params, account)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, %{accounts: result} |> Poison.encode!())
    else
      nil ->
        conn
        |> send_resp(404, "ffnot found")

      _ ->
        conn
        |> send_resp(400, "ff")
    end
  end

  defp validate_params(%{"keys" => keys} = params) do
    not_valid_keys = String.split(keys, ",") -- ["sex", "status", "interests", "country", "city"]

    if Enum.any?(not_valid_keys) |> IO.inspect(), do: :error
  end

  defp validate_params(%{"limit" => limit} = params) do
    case Integer.parse(limit) do
      {_, _} -> params
      _ -> :error
    end
  end
end
