defmodule Purple.Repo.Migrations.SetItemActiveAtNotNull do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :last_active_at, :naive_datetime, null: false
    end
  end
end
