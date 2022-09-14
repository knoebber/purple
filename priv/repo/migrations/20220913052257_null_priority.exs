defmodule Purple.Repo.Migrations.NullPriority do
  use Ecto.Migration

  def change do
    alter table("items") do
      modify :priority, :integer, null: true, default: nil
    end
  end
end
