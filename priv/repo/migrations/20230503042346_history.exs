defmodule Purple.Repo.Migrations.History do
  use Ecto.Migration

  def change do
    create table(:viewed_urls) do
      add :url, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :freshness, :integer, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:viewed_urls, [:url, :user_id])
  end
end
