defmodule Petaller.Repo.Migrations.AddTagsTable do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false
      timestamps()
    end

    create table(:item_tags) do
      add :item_id, references(:items), null: false
      add :tag_id, references(:tags), null: false
      timestamps()
    end
  end
end
