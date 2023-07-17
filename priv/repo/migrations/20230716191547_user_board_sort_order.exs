defmodule Purple.Repo.Migrations.UserBoardSortOrder do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :sort_order
    end

    alter table(:user_boards) do
      add :sort_order_json, :text, null: false, default: "{}"
    end
  end
end
