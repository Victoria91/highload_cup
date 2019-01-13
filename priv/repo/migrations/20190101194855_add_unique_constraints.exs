defmodule HighloadCup.Repo.Migrations.AddUniqueConstraints do
  use Ecto.Migration

  def change do
    create(unique_index(:accounts, [:email]))
    create(unique_index(:accounts, [:phone]))
  end
end
