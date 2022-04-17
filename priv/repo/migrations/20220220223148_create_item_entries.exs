defmodule Purple.Repo.Migrations.CreateItemEntries do
  use Ecto.Migration

  def change do
    create table(:item_entries) do
      add :content, :text
      add :item_id, references(:items, on_delete: :nothing)

      timestamps()
    end

    create index(:item_entries, [:item_id])
  end
end
