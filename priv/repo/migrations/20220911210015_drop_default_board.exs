defmodule Purple.Repo.Migrations.DropDefaultBoard do
  use Ecto.Migration

  def change do
    alter table("user_boards") do
      remove :is_default
    end
  end
end
