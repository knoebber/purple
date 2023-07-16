defmodule Purple.Repo.Migrations.DropItemStuff do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :priority
      remove :is_pinned
      add :sort_order, :integer, default: 0, null: false
    end
  end
end
