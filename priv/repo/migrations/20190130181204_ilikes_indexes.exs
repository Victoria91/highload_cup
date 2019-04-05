defmodule HighloadCup.Repo.Migrations.IlikesIndexes do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      modify(:likes, :text)
    end


    execute("CREATE INDEX idx_accounts_id ON accounts (id)")
    execute("CREATE INDEX idx_accounts_city ON accounts (city)")
    execute("CREATE INDEX idx_accounts_sex ON accounts (sex)")
    execute("CREATE INDEX idx_accounts_country ON accounts (country)")
    execute("CREATE INDEX idx_accounts_status ON accounts (status)")
    execute("CREATE INDEX idx_accounts_sname ON accounts (sname)")

    # execute "CREATE EXTENSION pg_trm"
    # execute "CREATE INDEX trgm_idx_accounts_likes ON accounts USING gin (likes gin_trgm_ops)"
  end

  def down do
    # alter table(:accounts) do
    # 	modify :likes,  {:array, :map}
    # end

    # execute "DROP INDEX trgm_idx_accounts_likes"

    execute("DROP INDEX idx_accounts_city")
    execute("DROP INDEX idx_accounts_id")
    execute("DROP INDEX idx_accounts_country")
    execute("DROP INDEX idx_accounts_sex")
    execute("DROP INDEX idx_accounts_status")
    execute("DROP INDEX idx_accounts_sname")
  end
end
