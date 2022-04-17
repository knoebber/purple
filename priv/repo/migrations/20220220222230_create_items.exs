defmodule Purple.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :description, :string, null: false
      add :priority, :integer, null: false, default: 1
      add :completed_at, :naive_datetime, null: true

      timestamps()
    end
  end
end
