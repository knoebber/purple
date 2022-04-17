defmodule Purple.Repo.Migrations.CollapseFiles do
  use Ecto.Migration

  def change do
    alter table("items") do
      add :show_files, :boolean, default: true, null: false
    end
  end
end
