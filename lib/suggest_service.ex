defmodule HighloadCup.SuggestService do
  alias :mnesia, as: Mnesia
  alias HighloadCup.{Repo, Models.Account}

  import Ecto.Query

  def fetch(%{"limit" => limit_value} = params, account) do
    # IO.inspect(params)

    result =
      perform(params, account)
      |> Enum.filter(fn %{weight: weight} -> weight > 0 end)
      |> Enum.sort_by(fn %{weight: weight} -> weight end)
      |> Enum.reverse()
      |> Enum.map(& &1.not_in_list)
      |> Enum.filter(fn v -> v end)
      |> Enum.map(fn list -> Enum.sort(list) |> Enum.reverse() end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.take(String.to_integer(limit_value))

    Account
    |> where([a], a.id in ^result)
    |> order_by([a], fragment("array_position(?, ?::bigint)", ^result, a.id))
    |> select([a], %{id: a.id, email: a.email, fname: a.fname, sname: a.sname, status: a.status})
    |> Repo.all()
  end

  def perform(_, %{likes: nil}), do: []

  def perform(params, %{id: id, sex: sex, likes: likes} = _account) do
    #   Mnesia.create_schema([node()])
    #   Mnesia.start()
    #   Mnesia.create_table(Likes, attributes: [:id, :liker_id, :sex, :account_id, :ts])

    # another_account = Repo.get(Account, 2113)

    # o_recs =
    #   another_account.likes
    #   |> Enum.map(fn %{"id" => id, "ts" => ts} ->
    #     {Likes, "#{id}_#{ts}", another_account.id, another_account.sex, id, ts}
    #   end)

    # a_recs =
    #   likes
    #   |> Enum.map(fn %{"id" => id, "ts" => ts} ->
    #     {Likes, "#{id}_#{ts}", account.id, account.sex, id, ts}
    #   end)
    #   # |> IO.inspect()

    # # > fun = :ets.fun2ms(fn {_, _, _, _, id, _} when id in [2804, 6522, 13478] -> id end)

    # records = o_recs ++ a_recs
    # data_to_write = fn -> records |> Enum.map(fn rec -> Mnesia.write(rec) end) end

    # Mnesia.transaction(data_to_write)

    likes = Jason.decode!(likes)
    account_like_ids = likes |> Enum.map(& &1["id"])

    accounts = fetch_similar_likes_accounts(id, sex, account_like_ids, params)

    accounts
    |> Enum.map(fn account ->
      fetch_res(account, account_like_ids, likes)
    end)
  end

  def fetch_similar_likes_accounts(id, account_sex, account_like_ids, params) do
    Account
    |> where(
      [a],
      fragment(
        "?::text similar to ?",
        a.likes,
        ^"%(#{format_ids(account_like_ids)})%"
      )
    )
    |> where_clause_by_params(params)
    |> where([a], a.sex == ^account_sex)
    |> where([a], a.id != ^id)
    |> select([a], a.likes)
    |> Repo.all()
  end

  defp format_ids(account_like_ids) do
    account_like_ids
    |> inspect(label: :infinity)
    |> String.replace("[", "")
    |> String.replace("]", "")
    |> String.replace(",", ",|")
    |> String.replace(" ", "")
  end

  def where_clause_by_params(query, %{"country" => country}) do
    query
    |> where([a], a.country == ^country)
  end

  def where_clause_by_params(query, %{"city" => country}) do
    query
    |> where([a], a.city == ^country)
  end

  def where_clause_by_params(query, _), do: query

  def write_account_likes(%{likes: likes, id: account_id, sex: sex, country: country, city: city}) do
    records =
      likes
      |> Enum.map(fn %{"id" => id, "ts" => ts} ->
        {Likes, "#{id}_#{ts}_#{country}_#{city}", account_id, sex, id, ts}
      end)

    data_to_write = fn -> records |> Enum.map(&Mnesia.write/1) end
    Mnesia.transaction(data_to_write)
  end

  def fetch_res(likes, account_like_ids, account_likes) do
    likes = likes |> Jason.decode!()
    result_ids = likes |> Enum.map(& &1["id"])

    results = result_ids |> Enum.group_by(fn like -> like in account_like_ids end)

    weights = results |> Map.fetch(true)
    not_in_list = results[false]

    if weights != :error do
      weights =
        weights
        |> Tuple.to_list()
        |> List.last()
        |> Enum.map(fn weight_id ->
          %{"ts" => ts} = likes |> Enum.find(fn %{"id" => id} -> id == weight_id end)

          %{"ts" => like_ts} = account_likes |> Enum.find(fn %{"id" => id} -> id == weight_id end)

          1 / abs(ts - like_ts)
        end)
    end

    total_weights =
      case weights do
        :error -> 0
        _ -> Enum.sum(weights)
      end

    %{not_in_list: not_in_list, weight: total_weights}
  end
end
