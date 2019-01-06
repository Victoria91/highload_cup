defmodule HighloadCup.RecommendService do
  alias HighloadCup.Models.Account
  alias HighloadCup.{Repo, SearchService}

  import Ecto.Query

  def perform(%{"limit" => limit_value} = search_params, %{id: id, interests: interests, sex: sex}) do
    # highload_cup=# select array_length(array(select unnest(ARRAY[1, 2, 7, 21]) except select unnest(ARRAY[2, 3, 4, 5])), 1);
    #  array_length
    # --------------
    #             3
    # (1 row)

    # current_time = :os.system_time(:millisecond)
    current_time = 1_546_083_844
    interests |> IO.inspect(label: "source interests")

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
        # premium_true: fragment("(premium->>'finish')::bigint > ?", ^current_time)

        # different_interests:
        #   fragment(
        #     "array (select unnest (array (select interests from accounts where id = ?)) except select unnest(?))",
        #     ^id,
        #     a.interests
        #   )
      })
      |> order_by(
        [a],
        desc:
          fragment(
            "((premium->>'finish')::bigint > ?)::int = 1 and premium is not null",
            ^current_time
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
