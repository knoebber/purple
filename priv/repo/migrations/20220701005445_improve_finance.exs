defmodule Purple.Repo.Migrations.ImproveFinance do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :notes, :text, default: "", null: false
    end

    alter table(:shared_budgets) do
      add :name, :string, default: "", null: false
    end

    create table(:shared_budget_manual_adjustments) do
      add :shared_budget_id, references(:shared_budgets), null: false
      add :cents, :integer, null: false
      add :description, :string, null: false, default: ""
      add :notes, :text, null: false, default: ""

      timestamps()
    end
  end
end
