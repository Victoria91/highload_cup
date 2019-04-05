defmodule HighloadCup do
  import Plug.Conn
  import Ecto.Query

  use Plug.Builder

  alias HighloadCup.Models.Account
  alias HighloadCup.{SearchService, GroupService, RecommendService, Repo, SuggestService}
  # plug Plug.Parsers, parsers: [:json],
  # pass:  ["text/*"],
  # json_decoder: Jason

  def perform(_, _) do
    HighloadCup.Dataloader.perform()
  end

  def new(conn, opts) do
    {:ok, body, conn} = read_body(conn, opts)
    {:ok, decoded_body} = body |> Jason.decode()

    if decoded_body["id"] == nil do
      conn
      |> send_resp(400, "")
      |> halt
    end

    case Account.insert(decoded_body) do
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

    with {:ok, decoded_body} <- Jason.decode(body),
         :ok <- validate_likes(decoded_body["likes"]),
         {:ok, _account} <- Account.update(id, decoded_body) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(202, "{}")
    else
      {:error, %Ecto.Changeset{}} ->
        conn
        |> send_resp(400, "")

      {:error, :not_valid_like} ->
        conn
        |> send_resp(400, "")

      _ ->
        conn
        |> send_resp(404, "")
    end
  end

  def likes(conn, opts) do
    {:ok, body, conn} = read_body(conn, opts)
    {:ok, decoded_body} = body |> Jason.decode()

    user_ids =
      decoded_body["likes"]
      |> Enum.map(fn %{"likee" => id, "liker" => account_id} -> [id, account_id] end)
      |> List.flatten()
      |> Enum.uniq()

    account_ids_length = length(user_ids)

    with :ok <- validate_likes(decoded_body["likes"]),
         nil <- Enum.find(user_ids, fn account_id -> is_integer(account_id) == false end),
         ^account_ids_length <-
           Repo.one(from(a in Account, select: count("*"), where: a.id in ^user_ids)) do
      decoded_body["likes"]
      |> Enum.group_by(& &1["liker"])
      |> Enum.each(fn {account_id, likes_list} ->
        new_likes =
          likes_list |> Enum.map(fn %{"likee" => id, "ts" => ts} -> %{"id" => id, "ts" => ts} end)

        %{likes: likes} = Repo.get(Account, account_id)

        {:ok, result} =
          Account.update(account_id, %{
            likes: "#{delete_last(likes)}#{Jason.encode!(new_likes) |> delete_first(likes)}"
          })

        # IO.inspect result.likes, label: "likes after update"
        # Jason.decode! result.likes
      end)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(202, "{}")
    else
      _ ->
        conn
        |> send_resp(400, "")
    end
  end

  defp delete_last(nil), do: ""
  defp delete_last(string), do: String.replace(string, "]", ",")
  defp delete_first(string, nil), do: string
  defp delete_first(string, _old_likes), do: String.replace(string, "[", "")

  def filter(conn, _) do
    params = Plug.Conn.Query.decode(conn.query_string)

    with %{} = params <- validate_params(params),
         {:ok, result} <- SearchService.perform(params) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, %{accounts: result} |> Jason.encode!())
    else
      _ ->
        conn
        |> send_resp(400, "err")
    end
  end

  def group(conn, _) do
    params = Plug.Conn.Query.decode(conn.query_string)

    case validate_params(params) do
      :error ->
        conn
        |> send_resp(400, "err")

      params ->
        res = GroupService.perform(params) |> cut_blank_values

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, %{groups: res} |> Jason.encode!())
    end
  end

  def recommend(%{path_params: %{"id" => id}} = conn, _opts) do
    decoded_params = Plug.Conn.Query.decode(conn.query_string)

    with %{} = params <- validate_params(decoded_params),
         %Account{} = account <- Repo.get(Account, id) do
      result = RecommendService.perform(params, account)

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, %{accounts: result} |> Jason.encode!())
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
      result = SuggestService.fetch(params, account) |> cut_blank_values

      # result |> Enum.map(& &1.id) |> IO.inspect(label: "resulted ids")

      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, %{accounts: result} |> Jason.encode!())
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
      | "keys" => String.split(keys, ",") |> Enum.map(&String.to_atom/1)
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

  defp validate_likes(nil), do: :ok

  defp validate_likes(params) do
    not_valid_like =
      params
      |> Enum.map(fn %{"ts" => ts} -> ts end)
      |> Enum.find(fn timestamp -> is_integer(timestamp) == false end)

    if not_valid_like, do: {:error, :not_valid_like}, else: :ok
  end
end
