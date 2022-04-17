defmodule Purple.Repo.Migrations.RunDescriptionDefault do
  use Ecto.Migration

  def change do
    alter table("runs") do
      modify(:description, :text, null: false, default: "")
    end
  end
end
