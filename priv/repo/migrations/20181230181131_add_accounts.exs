defmodule HighloadCup.Repo.Migrations.AddAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add(:email, :string, size: 40)
      add(:fname, :string, size: 50)
      add(:sname, :string, size: 50)
      add(:phone, :string, size: 16)
      add(:sex, :string, size: 1)
      add(:birth, :integer)
      add(:country, :string, size: 50)
      add(:city, :string, size: 50)
      add(:joined, :integer)
      add(:status, :string)
      add(:interests, {:array, :string})
      add(:premium, :json)
      add(:likes, {:array, :map})

      timestamps
    end
  end
end
