defmodule Petaller.Repo.Migrations.ChangeItemCompletedToDatetime do
  use Ecto.Migration

  def change do
    alter table("items") do
      remove :completed
      add :completed_at, :naive_datetime, null: true
    end
  end
end
