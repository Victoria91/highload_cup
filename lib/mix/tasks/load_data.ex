defmodule Mix.Tasks.LoadData do
  use Mix.Task
  import Mix.Ecto

  def run(_) do
    Mix.Task.run("app.start")

    HighloadCup.Dataloader.perform()
  end
end
