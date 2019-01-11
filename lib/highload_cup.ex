defmodule HighloadCup do
  import Plug.Conn
  use Plug.Builder

  alias HighloadCup.Models.Account
  alias HighloadCup.{SearchService, GroupService, RecommendService, Repo, SuggestService}
  # plug Plug.Parsers, parsers: [:json],
  # pass:  ["text/*"],
  # json_decoder: Poison

  def new(conn, opts) do
    {:ok, body, conn} = read_body(conn, opts)
    {:ok, decoded_body} = body |> Poison.decode() |> IO.inspect()

    case Account.insert(decoded_body) |> IO.inspect() do
      {:ok, _account} ->
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
      {:ok, _account} ->
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

  def filter(conn, _) do
    params = Plug.Conn.Query.decode(conn.query_string) |> IO.inspect()

    with %{} = params <- validate_params(params),
         {:ok, result} <- SearchService.perform(params) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, %{accounts: result} |> Poison.encode!())
    else
      _ ->
        conn
        |> send_resp(400, "err")
    end
  end

  def group(conn, _) do
    params = Plug.Conn.Query.decode(conn.query_string) |> IO.inspect()

    case validate_params(params) do
      :error ->
        conn
        |> send_resp(400, "err")

      params ->
        res = GroupService.perform(params) |> cut_blank_values

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

  def suggest(%{path_params: %{"id" => id}} = conn, _opts) do
    decoded_params = Plug.Conn.Query.decode(conn.query_string)

    with %{} = params <- validate_params(decoded_params),
         %Account{} = account <- Repo.get(Account, id) do
      result =
        SuggestService.fetch(params, account) |> cut_blank_values |> IO.inspect(label: "resu;t")

        result |> Enum.map(& &1.id) |> IO.inspect(label: "resulted ids")

      # require IEx; IEx.pry()
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

  def cut_blank_values(result) do
    result
    |> Enum.map(fn res -> Enum.filter(res, fn {_, v} -> v end) |> Enum.into(%{}) end)
  end

  defp validate_params(%{"keys" => keys} = params) do
    params = %{
      params
      | "keys" => String.split(keys, ",") |> IO.inspect() |> Enum.map(&String.to_atom/1)
    }

    if Enum.any?(params["keys"] -- [:sex, :status, :interests, :country, :city]) do
      :error
    else
      params
    end
  end

  defp validate_params(%{"city" => ""}), do: :error

  defp validate_params(%{"country" => ""}), do: :error

  defp validate_params(%{"limit" => limit} = params) do
    case Integer.parse(limit) do
      {int, _} -> if int > 0, do: params, else: :error
      _ -> :error
    end
  end
end
