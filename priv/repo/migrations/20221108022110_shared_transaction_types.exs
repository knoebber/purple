defmodule Purple.Repo.Migrations.SharedTransactionTypes do
  use Ecto.Migration

  def change do
    alter table(:shared_transactions) do
      add :type, :string, default: "SHARE", null: false
    end
  end
end
