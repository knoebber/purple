defmodule Petaller.Repo.Migrations.AddItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :description, :string
      add :priority, :integer, default: 3
      add :completed, :boolean

      timestamps()
    end
  end
end
