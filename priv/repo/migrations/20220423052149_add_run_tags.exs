defmodule Purple.Repo.Migrations.AddRunTags do
  use Ecto.Migration

  def change do
    create table(:run_tags) do
      add :run_id, references(:runs), null: false
      add :tag_id, references(:tags), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:run_tags, [:run_id, :tag_id])
  end
end
