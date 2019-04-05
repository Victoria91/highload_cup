defmodule HighloadCup.RecommendService do
  alias HighloadCup.Models.Account
  alias HighloadCup.{Repo, SearchService}

  import Ecto.Query

  @current_time Application.get_env(:highload_cup, :time)[:current_time]

  def perform(%{"limit" => limit_value} = search_params, %{id: id, interests: interests, sex: sex}) do
    # current_time = current_time

    if interests do
      base_query(search_params)
      |> select([a], %{
        id: a.id,
        email: a.email,
        status: a.status,
        fname: a.fname,
        sname: a.sname,
        birth: a.birth,
        premium: a.premium
      })
      |> order_by(
        [a],
        desc:
          fragment(
            "((premium->>'finish')::bigint > ?)::int = 1 and premium is not null",
            ^@current_time
          ),
        desc: a.status == "свободны",
        desc: a.status == "всё сложно",
        asc:
          fragment(
            "cardinality ( array ( select unnest (array (select interests from accounts where id = ?)) except select unnest(interests ) ) )",
            ^id
          ),
        asc: fragment("@(birth - (select birth from accounts where id = ?))", ^id)
      )
      |> where([a], a.id != ^id)
      |> where([a], a.sex != ^sex)
      |> where(
        [a],
        fragment(
          "cardinality(array (select unnest (array (select interests from accounts where id = ?)) except select unnest(?))) < ?",
          ^id,
          a.interests,
          ^length(interests)
        )
      )
      |> limit(^limit_value)
      |> Repo.all()
      |> Enum.map(fn res -> Enum.filter(res, fn {_, v} -> v end) |> Enum.into(%{}) end)
    else
      []
    end
  end

  def base_query(%{"city" => city}) do
    SearchService.where_clause(Account, {"city", "eq", city})
  end

  def base_query(%{"country" => country}) do
    SearchService.where_clause(Account, {"country", "eq", country})
  end

  def base_query(_), do: Account
end
