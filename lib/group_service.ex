defmodule HighloadCup.GroupService do
  alias HighloadCup.Models.Account
  alias HighloadCup.SearchService

  import Ecto.Query

  def perform(%{"limit" => limit, "order" => order, "keys" => keys} = query_map) do
    list_of_group_fields =
      keys
      |> String.split(",")
      |> Enum.map(&String.to_atom/1)

    query_map
    |> base_query
    |> group_by_clause(list_of_group_fields)
    |> order_by_clause(order)
    |> limit_clause(limit)
    |> IO.inspect()
    |> HighloadCup.Repo.all()
  end

  def group_by_clause(query, field_atom) when is_atom(field_atom) do
    query
    |> where([a], not is_nil(field(a, ^field_atom)))
    |> group_by([a], field(a, ^field_atom))
  end

  def group_by_clause(query, array_of_fields) do
    Enum.reduce(array_of_fields, query, fn field, acc -> group_by_clause(acc, field) end)
    |> select([a], merge(map(a, ^array_of_fields), %{count: count(a.id)}))
  end

  def order_by_clause(query, "-1") do
    query
    |> order_by(desc: :count)
  end

  def order_by_clause(query, "1") do
    query
    |> order_by(asc: :count)
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

  def perform_filtering([]), do: Account

  def perform_filtering(filter_values_list) do
    Enum.reduce(filter_values_list, Account, fn {field, value}, acc ->
      SearchService.where_clause(acc, {field, "eq", value})
    end)
  end
end
