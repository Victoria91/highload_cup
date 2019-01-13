defmodule HighloadCup.SearchService do
  import Ecto.Query

  alias HighloadCup.Models.Account
  alias HighloadCup.Repo

  @legal_ops [
    "year",
    "eq",
    "null",
    "neq",
    "now",
    "domain",
    "lt",
    "gt",
    "any",
    "starts",
    "code",
    "contains"
  ]

  def perform(%{"limit" => limit} = query_map) do
    decoded_query =
      query_map
      |> decode_query
      |> IO.inspect(label: "decoded")

    illigal_clauses = Enum.any?(decoded_query, fn {_, op, _} -> op not in @legal_ops end)

    perform_where_query(decoded_query, limit, illegal_clauses: illigal_clauses)
  end

  def perform_where_query(_, _, illegal_clauses: true), do: :error

  def perform_where_query(decoded_query, limit, illegal_clauses: false) do
    try do
      result =
        Enum.reduce(decoded_query, Account, fn query_line, acc ->
          where_clause(acc, query_line)
        end)
        |> select_clause(values_for_select(decoded_query))
        |> order_clause()
        |> limit_clause(limit)
        |> Repo.all()

      {:ok, result}
    rescue
      _e in [Ecto.Query.CastError, FunctionClauseError] ->
        :error
    end
  end

  defp values_for_select(decoded_query) do
    decoded_query
    |> Enum.reject(fn {field, _, _} -> field in ["interests", "likes"] end)
    |> Enum.reject(fn {_, operator, value} -> operator == "null" && value == "1" end)
    |> Enum.map(fn {field, _, _} -> String.to_atom(field) end)
  end

  def select_clause(query, []) do
    query
    |> select([a], %{id: a.id, email: a.email})
  end

  def select_clause(query, array_of_fields) do
    array_of_fields |> IO.inspect(label: "array_of_fields")

    query
    |> select([a], merge(map(a, ^array_of_fields), %{id: a.id, email: a.email}))
  end

  def limit_clause(query, limit_value) do
    query
    |> limit(^limit_value)
  end

  def order_clause(query) do
    query
    |> order_by([a], desc: a.id)
  end

  def where_clause(query, {field_name, operation, value})
      when operation in ["eq", "year"] and field_name in ["birth", "joined"] do
    {start_date, end_date} = fetch_year_boundaries(value)
    # + 631152000
    query
    |> where(
      [a],
      fragment("? between ? and ?", field(a, ^String.to_atom(field_name)), ^start_date, ^end_date)
    )
  end

  def where_clause(query, {"premium", "now", "1"}) do
    query
    |> where([a], fragment("(premium->>'finish')::bigint > ?", 1_546_083_844))

    # |> where([a], fragment("(premium->>'finish')::bigint > ?", ^:os.system_time(:millisecond)))
  end

  def where_clause(query, {field_name, "eq", value})
      when field_name in ["country", "status", "sex", "sname", "city"] do
    query
    |> where([a], field(a, ^String.to_atom(field_name)) == ^value)
  end

  def where_clause(query, {"status", "neq", value}) do
    query
    |> where([a], a.status != ^value)
  end

  def where_clause(query, {"likes", _, values}) when is_list(values) do
    Enum.reduce(values, query, fn value, acc ->
      where_clause(acc, {"likes", "contains", value})
    end)
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

  def where_clause(query, {field_name, "gt", value}) when field_name != "city" do
    query
    |> where([a], field(a, ^String.to_atom(field_name)) > ^value)
  end

  # highload_cup=# SELECT * FROM accounts WHERE interests && ARRAY['one', 'fsfdf']::varchar[];
  def where_clause(query, {"interests", "any", value}) do
    query
    |> where(
      [a],
      fragment(
        "? && ARRAY[?]::varchar[]",
        a.interests,
        type(^String.split(value, ","), {:array, :string})
      )
    )
  end

  # highload_cup=# SELECT * FROM accounts WHERE interests @> '{one, fsfdf}'::varchar[];
  def where_clause(query, {"interests", "contains", value}) do
    query
    |> where([a], fragment("? @> ?::varchar[]", a.interests, ^String.split(value, ",")))
  end

  def where_clause(query, {"sname", "starts", value}) do
    query
    |> where([a], ilike(a.sname, ^"#{value}%"))
  end

  def where_clause(query, {"phone", "code", value}) do
    query
    |> where([a], ilike(a.phone, ^"%(#{value})%"))
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

  def fetch_year_boundaries(year) do
    year = String.to_integer(year)
    {:ok, end_date, 0} = DateTime.from_iso8601("#{year}-12-31T23:59:59Z")
    {:ok, start_date, 0} = DateTime.from_iso8601("#{year}-01-01T00:00:00Z")

    {DateTime.to_unix(start_date), DateTime.to_unix(end_date)}
  end

  def decode_query(map) do
    map
    |> normalize_params
    |> Enum.reject(fn {key, _} -> key in ["limit", "query_id"] end)
    |> Enum.map(fn {key, value} ->
      [column, operation] = String.split(key, "_")
      {column, operation, value}
    end)
  end

  def normalize_params(%{"likes_contains" => value} = params) do
    %{params | "likes_contains" => String.split(value, ",")}
  end

  def normalize_params(params), do: params
end
