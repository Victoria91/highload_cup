defmodule HighloadCup.GroupService do
  import Ecto.Query

  def perform(%{"limit" => limit, "order" => order, "keys" => keys} = query_map) do
    [{field, value}] =
      query_map
      |> Map.drop(["order", "keys", "limit", "query_id"])
      |> Map.to_list()
      |> IO.inspect(label: "values for filter")

    list_of_group_fields =
      keys
      |> String.split(",")
      |> Enum.map(&String.to_atom/1)

    HighloadCup.SearchService.where_clause(HighloadCup.Models.Account, {field, "eq", value})
    |> group_by_clause(list_of_group_fields)
    |> order_by_clause(order)
    |> limit_clause(limit)
    |> IO.inspect()
    |> HighloadCup.Repo.all()
  end

  def group_by_clause(query, field_atom) when is_atom(field_atom) do
    query
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
end
