defmodule Purple.Repo.Migrations.AddPinnedItems do
  use Ecto.Migration

  def change do
    alter table("items") do
      add :is_pinned, :boolean, default: false
    end
  end
end
