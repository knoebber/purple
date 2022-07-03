defmodule Purple.Repo.Migrations.BalanceAdjustmentTags do
  use Ecto.Migration

  def change do
    create table(:shared_budget_adjustment_tags) do
      add :shared_budget_adjustment_id,
          references(:shared_budget_adjustments, on_delete: :delete_all),
          null: false

      add :tag_id, references(:tags), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:shared_budget_adjustment_tags, [:shared_budget_adjustment_id, :tag_id])
  end
end
