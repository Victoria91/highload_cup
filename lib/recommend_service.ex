defmodule HighloadCup.RecommendService do
  alias HighloadCup.Models.Account
  alias HighloadCup.Repo

  import Ecto.Query

  def perform(%{"limit" => limit_value} = search_params, %{id: id, interests: interests}) do
    # highload_cup=# select array_length(array(select unnest(ARRAY[1, 2, 7, 21]) except select unnest(ARRAY[2, 3, 4, 5])), 1);
    #  array_length
    # --------------
    #             3
    # (1 row)
    current_time = :os.system_time(:millisecond)
    interests |> IO.inspect(label: "source interests")

    Account
    |> select([a], %{
      id: a.id,
      interests: a.interests,
      birth: a.birth,
      status: a.status,
      premium: fragment("(premium->>'finish')::bigint > ?", ^current_time)

      # different_interests:
      #   fragment(
      #     "array (select unnest (array (select interests from accounts where id = ?)) except select unnest(?))",
      #     ^id,
      #     a.interests
      #   )
    })
    |> order_by([a], [
      fragment("(premium->>'finish')::bigint > ? DESC NULLS LAST", ^current_time),
      desc: a.status == "свободны",
      desc: a.status == "всё сложно",
      asc:
        fragment(
          "cardinality ( array ( select unnest (array (select interests from accounts where id = ?)) except select unnest(interests ) ) )",
          ^id
        ),
      asc: fragment("@(birth - (select birth from accounts where id = ?))", ^id)
    ])
    |> where([a], a.id != ^id)
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
  end
end
