defmodule Purple.Repo.Migrations.TransactionCategory do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :category, :string, default: "OTHER", null: false
    end
  end
end
