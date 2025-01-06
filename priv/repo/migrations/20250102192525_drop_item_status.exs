defmodule Purple.Repo.Migrations.DropItemStatus do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :status
      remove :completed_at
    end
  end
end
