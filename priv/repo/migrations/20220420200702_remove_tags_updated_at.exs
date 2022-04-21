defmodule Purple.Repo.Migrations.RemoveTagsUpdatedAt do
  use Ecto.Migration

  def change do
    alter table("tags") do
      remove :updated_at
    end

    alter table("item_tags") do
      remove :updated_at
    end
  end
end
