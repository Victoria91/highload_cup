defmodule HighloadCup.SearchService do
  import Ecto.Query
  alias HighloadCup.Models.Account
  alias HighloadCup.Repo

  def perform(query_map) do
    decoded_query =
      query_map
      |> decode_query
      |> IO.inspect(label: "decoded")

    Enum.reduce(decoded_query, Account, fn query_line, acc -> where_clause(acc, query_line) end)
    |> Repo.all()
  end

  def where_clause(query, {"birth", "lt", value}) do
    query
    |> where([a], a.birth > ^value)
  end

  def where_clause(query, {"premium", "now", "1"}) do
    query
    |> where([a], fragment("(premium->>'finish')::bigint > ?", ^:os.system_time(:millisecond)))
  end

  def where_clause(query, {field_name, "eq", value})
      when field_name in ["country", "status", "sex", "sname", "city"] do
    query
    |> where([a], field(a, ^String.to_atom(field_name)) == ^value)
  end

  def where_clause(query, {"status", "neq", value}) do
    query
    |> where([a], a.country != ^value)
  end

  def where_clause(query, {"likes", _, value}) do
    query
    |> where([a], fragment("?::text ilike ?", a.likes, ^"% #{value},%"))
  end

  def where_clause(query, {"email", "domain", value}) do
    query
    |> where([a], ilike(a.email, ^"%#{value}"))
  end

  def where_clause(query, {field_name, "lt", value}) do
    query
    |> where([a], field(a, ^String.to_atom(field_name)) < ^value)
  end

  def where_clause(query, {field_name, "gt", value}) do
    query
    |> where([a], field(a, ^String.to_atom(field_name)) > ^value)
  end

  # highload_cup=# SELECT * FROM accounts WHERE interests && ARRAY['one', 'fsfdf']::varchar[];
  def where_clause(query, {"interests", "any", value}) do
    query
    |> where([a], fragment("? && ARRAY[?]::varchar[]", a.interests, ^value))
  end

  # highload_cup=# SELECT * FROM accounts WHERE interests @> '{one, fsfdf}'::varchar[];
  def where_clause(query, {"interests", "contains", value}) do
    query
    |> where([a], fragment("? @> ?::varchar[]", a.interests, ^String.split(value, ",")))
  end

  # 4	fname	eq - соответствие конкретному имени;
  # any - соответствие любому имени из перечисленных через запятую;
  # null - выбрать всех, у кого указано имя (если 0) или не указано (если 1);
  def where_clause(query, {field_name, "any", value}) when field_name in ["fname", "city"] do
    value_for_search = value |> String.downcase() |> String.replace(",", "|")

    query
    |> where(
      [a],
      fragment(
        "lower(?) similar to ?",
        field(a, ^String.to_atom(field_name)),
        ^"%#{value_for_search}%"
      )
    )
  end

  def where_clause(query, {field_name, "null", "0"}) do
    query
    |> where([a], not is_nil(field(a, ^String.to_atom(field_name))))
  end

  def where_clause(query, {field_name, "null", "1"}) do
    query
    |> where([a], is_nil(field(a, ^String.to_atom(field_name))))
  end

  def decode_query(map) do
    map
    |> Enum.reject(fn {key, _} -> key in ["limit", "query_id"] end)
    |> Enum.map(fn {key, value} ->
      [column, operation] = String.split(key, "_")
      {column, operation, value}
    end)
  end
end
