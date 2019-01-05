defmodule HighloadCupTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias HighloadCup.Models.Account
  alias HighloadCup.Repo

  @opts HighloadCup.init([])

  describe "accounts/new" do
    setup do
      valid_params = %{
        sname: "Хопетачан",
        email: "orhograanenor@yahoo.com",
        country: "Голция",
        interests: [],
        birth: 736_598_811,
        id: 50000,
        sex: "f",
        likes: [
          %{ts: 1_475_619_112, id: 38753},
          %{ts: 1_464_366_718, id: 14893},
          %{ts: 1_510_257_477, id: 37967},
          %{ts: 1_431_722_263, id: 38933}
        ],
        premium: %{start: 1_519_661_251, finish: 1_522_253_251},
        status: "всё сложно",
        fname: "Полина",
        joined: 1_466_035_200
      }

      {:ok, valid_params: valid_params}
    end

    test "valid data - returns blank result with 201 status", %{valid_params: valid_params} do
      # FIXME
      Repo.delete_all(Account)

      conn = conn(:post, "/accounts/new", Poison.encode!(valid_params))

      # Invoke the plug
      conn = HighloadCup.Router.call(conn, @opts)

      # Assert the response and status

      assert conn.state == :sent
      assert conn.status == 201
      assert conn.resp_body == "{}"
    end

    test "invalid data - returns blank result with 400 status", %{valid_params: valid_params} do
      # FIXME
      Repo.delete_all(Account)

      Account.insert(%{email: valid_params[:email]}) |> IO.inspect(label: "test")

      conn = conn(:post, "/accounts/new", Poison.encode!(valid_params))

      conn = HighloadCup.Router.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end
  end
end
