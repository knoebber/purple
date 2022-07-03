defmodule Purple.Repo.Migrations.FixBalanceAdjustments do
  use Ecto.Migration

  def change do
    rename table(:shared_budget_manual_adjustments), to: table(:shared_budget_adjustments)

    alter table(:shared_budget_adjustments) do
      add :user_id, references(:users), null: false
    end
  end
end
