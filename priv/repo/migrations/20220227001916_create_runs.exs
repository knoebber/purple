defmodule Petaller.Repo.Migrations.CreateRuns do
  use Ecto.Migration

  def change do
    create table(:runs) do
      add :miles, :float
      add :seconds, :integer
      add :description, :text

      timestamps()
    end
  end
end
