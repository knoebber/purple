defmodule Petaller.Repo.Migrations.ImproveRunsTable do
  use Ecto.Migration

  def change do
    alter table("runs") do
      modify :miles, :float, null: false
      add :date, :date, null: false, default: fragment("current_date")
    end
  end
end
