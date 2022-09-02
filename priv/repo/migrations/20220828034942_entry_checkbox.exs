defmodule Purple.Repo.Migrations.EntryCheckbox do
  use Ecto.Migration

  def change do
    create table(:entry_checkboxes) do
      add :item_entry_id, references(:item_entries, on_delete: :delete_all), null: false
      add :description, :string, null: false
      add :is_done, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:entry_checkboxes, [:item_entry_id, :description])
  end
end
