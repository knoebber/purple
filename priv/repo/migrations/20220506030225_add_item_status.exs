defmodule Purple.Repo.Migrations.AddItemStatus do
  use Ecto.Migration

  def change do
    alter table("items") do
      add :status, :string, default: "TODO", null: false
    end
  end
end
