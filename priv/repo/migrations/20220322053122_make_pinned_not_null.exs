defmodule Purple.Repo.Migrations.MakePinnedNotNull do
  use Ecto.Migration

  def change do
    alter table("items") do
      modify :is_pinned, :boolean, null: false, default: false
    end
  end
end
