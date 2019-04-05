defmodule HighloadCup.Dataloader do
  alias HighloadCup.Models.Account

  def perform do
    Logger.remove_backend(:console)

    :zip.unzip('/tmp/data/data.zip', [{:cwd, ~c'ddddd/'}]) |> inspect |> IO.puts()

    Path.wildcard("ddddd/*.json")
    |> Enum.chunk_every(10)
    |> Enum.each(&handle_list_loading/1)
  end

  defp handle_list_loading(list) do
    list
    |> Enum.map(fn file_path -> Task.async(fn -> insert_data(file_path) end) end)
    |> Enum.map(fn res -> Task.await(res, :infinity) end)
  end

  defp insert_data(file_path) do
    IO.inspect("handling #{file_path}...")

    file_path
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("accounts")
    |> Enum.chunk_every(600)
    |> Enum.each(fn list_of_map ->
      HighloadCup.Repo.insert_all(Account, Enum.map(list_of_map, &convert_to_kw/1))
    end)
  end

  def convert_to_kw(%{"likes" => likes} = map) when not is_nil(likes) do
    %{map | "likes" => Jason.encode!(likes)} |> to_keyword_list
  end

  def convert_to_kw(map), do: to_keyword_list(map)

  def to_keyword_list(map) do
    Enum.map(map, fn {k, v} ->
      {String.to_atom("#{k}"), v}
    end)
  end
end
