defmodule Purple.Repo.Migrations.CascadeDeleteTagRefs do
  use Ecto.Migration

  def change do
    drop constraint(:run_tags, :run_tags_run_id_fkey)
    drop constraint(:item_tags, :item_tags_item_id_fkey)

    alter table(:run_tags) do
      modify :run_id, references(:runs, on_delete: :delete_all), null: false
    end

    alter table(:item_tags) do
      modify :item_id, references(:items, on_delete: :delete_all), null: false
    end
  end
end
