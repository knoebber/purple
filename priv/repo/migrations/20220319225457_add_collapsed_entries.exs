defmodule Petaller.Repo.Migrations.AddCollapsedEntries do
  use Ecto.Migration

  def change do
    alter table("item_entries") do
      add :is_collapsed, :boolean, default: false
    end
  end
end
