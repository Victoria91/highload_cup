defmodule HighloadCup.GroupService do
  alias HighloadCup.Models.Account
  alias HighloadCup.SearchService

  import Ecto.Query

  def perform(%{"limit" => limit, "order" => order, "keys" => keys} = query_map) do
    query_map
    |> base_query
    |> group_by_clause(keys)
    |> order_by_clause(order, keys)
    |> limit_clause(limit)
    |> IO.inspect()
    |> HighloadCup.Repo.all()
  end

  def group_by_clause(query, :interests) do
    query
    |> group_by([a], fragment("unnest_interests"))
  end

  def group_by_clause(query, field_atom) when is_atom(field_atom) do
    query
    |> group_by([a], field(a, ^field_atom))
  end

  def group_by_clause(query, array_of_fields) when array_of_fields == [:interests] do
    Enum.reduce(array_of_fields, query, fn field, acc -> group_by_clause(acc, field) end)
    |> select([a], %{count: count(a.id), interests: fragment("unnest(?) as unnest_interests", a.interests)})
  end

  def group_by_clause(query, array_of_fields) do
    array_of_fields |> IO.inspect
    Enum.reduce(array_of_fields, query, fn field, acc -> group_by_clause(acc, field) end)
    |> select([a], merge(map(a, ^array_of_fields), %{count: count(a.id)}))
  end

  def order_by_clause(query, "-1", [:interests]) do
    query
    |> order_by([desc: :count, desc: fragment("unnest_interests")])
  end

  def order_by_clause(query, "1", [:interests]) do
    query
    |> order_by([asc: :count, asc: fragment("unnest_interests")])
  end

  def order_by_clause(query, "-1", keys) do
    query
    |> order_by(^generate_order_by_params(keys, :desc))
  end

  def order_by_clause(query, "1", keys) do
    query
    |> order_by(^generate_order_by_params(keys, :asc))
  end

  def limit_clause(query, limit_value) do
    query
    |> limit(^limit_value)
  end

  def base_query(query_map) do
    filter_values =
      query_map
      |> Map.drop(["order", "keys", "limit", "query_id"])
      |> Map.to_list()

    perform_filtering(filter_values)
  end

  def generate_order_by_params(keys, order) when order in [:desc, :asc] do
    Enum.reduce(keys, ["#{order}": :count], fn key, acc -> acc ++ ["#{order}": key] end)
  end

  def perform_filtering([]), do: Account

  def perform_filtering(filter_values_list) do
    Enum.reduce(filter_values_list, Account, fn {field, value}, acc ->
      SearchService.where_clause(acc, where_clause_data({field, value}))
    end)
  end

  defp where_clause_data({"interests", value}), do: {"interests", "contains", value}
  defp where_clause_data({field, value}), do: {field, "eq", value}
end
