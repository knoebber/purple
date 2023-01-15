defmodule Purple.Repo.Migrations.RSSfeed do
  use Ecto.Migration

  def change do
    create table(:rss_feeds) do
      add :url, :string, null: false
      add :title, :string, null: false

      timestamps()
    end

    create unique_index(:rss_feeds, [:url])

    create table(:rss_feed_items) do
      add :link, :string, null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :rss_feed_id, references(:rss_feeds, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rss_feed_items, [:link])

    create table(:rss_feed_item_user_state) do
      add :is_read, :boolean, null: false, default: false
      add :is_hidden, :boolean, null: false, default: false
      add :rss_feed_item_id, references(:rss_feed_items, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rss_feed_item_user_state, [:rss_feed_item_id, :user_id])
  end
end
