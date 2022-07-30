defmodule Purple.Repo.Migrations.CustomBoards do
  use Ecto.Migration

  def change do
    create table(:user_boards) do
      add :user_id, references(:users), null: false
      add :name, :string, null: false
      add :is_default, :boolean, default: false, null: false
      add :show_done, :boolean, default: false, null: false

      timestamps()
    end

    create table(:user_board_tags) do
      add :user_board_id, references(:user_boards, on_delete: :delete_all), null: false
      add :tag_id, references(:tags), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:user_board_tags, [:user_board_id, :tag_id])
  end
end
