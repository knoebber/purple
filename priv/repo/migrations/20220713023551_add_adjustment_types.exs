defmodule Purple.Repo.Migrations.AddAdjustmentTypes do
  use Ecto.Migration

  def change do
    alter table(:shared_budget_adjustments) do
      add :type, :string, default: "SHARE", null: false
    end
  end
end
