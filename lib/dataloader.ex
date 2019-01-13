defmodule HighloadCup.Dataloader do
  alias HighloadCup.Models.Account

  def perform do
    Path.wildcard("test_accounts/data/*.json")
    |> Enum.map(fn file_path -> Task.async(fn -> insert_data(file_path) end) end)
    |> Enum.map(&Task.await/1)
  end

  defp insert_data(file_path) do
    file_path
    |> File.read!()
    |> Poison.decode!()
    |> Map.fetch!("accounts")
    |> Enum.each(fn rec -> Account.insert(rec, skip_validations: true) end)
  end
end
