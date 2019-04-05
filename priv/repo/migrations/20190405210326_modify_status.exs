defmodule HighloadCup.Repo.Migrations.ModifyStatus do
  use Ecto.Migration
import EctoEnum
  defenum StatusEnum, :status, [ "всё сложно", "заняты", "свободны"]

def up do
  StatusEnum.create_type
  # create table(:users_pg) do
  #   add :status, StatusEnum.type()
  # end
  

 		
    alter table(:accounts) do
      remove(:status)
    end

    alter table(:accounts) do
      add(:status, StatusEnum.type())
    end
    execute("CREATE INDEX idx_accounts_status ON accounts (status)")


	end


	def down do
		    alter table(:accounts) do
      modify(:status, :string, size: 50)
    end

	end
end