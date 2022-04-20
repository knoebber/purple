defmodule Purple.Repo.Migrations.ImproveTags do
  use Ecto.Migration

  def change do
    alter table("tags") do
      modify(:name, :string, null: false, size: 32)
    end

    create unique_index(:tags, [:name])
    create unique_index(:item_tags, [:item_id, :tag_id])
  end
end
