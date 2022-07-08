defmodule Purple.Repo.Migrations.CollapseAdjustments do
  use Ecto.Migration

  def change do
    alter table(:shared_budgets) do
      add :show_adjustments, :boolean, default: false, null: false
    end
  end
end
