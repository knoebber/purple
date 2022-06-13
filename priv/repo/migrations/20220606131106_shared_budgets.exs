defmodule Purple.Repo.Migrations.SharedBudgets do
  use Ecto.Migration

  def change do
    create table(:shared_budgets) do
      timestamps(updated_at: false)
    end

    create table(:shared_transactions) do
      add :shared_budget_id, references(:shared_budgets), null: false
      add :transaction_id, references(:transactions), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:shared_transactions, [:shared_budget_id, :transaction_id])
  end
end
