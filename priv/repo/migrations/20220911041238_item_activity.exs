defmodule Purple.Repo.Migrations.ItemActivity do
  use Ecto.Migration

  def change do

    alter table(:items) do
      add :last_active_at, :naive_datetime, null: true
    end
  end
end
