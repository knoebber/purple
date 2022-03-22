defmodule Petaller.Repo.Migrations.AddEntrySortOrder do
  use Ecto.Migration

  def change do
    alter table("item_entries") do
      add :sort_order, :integer, default: 0
    end
  end
end
