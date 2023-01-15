defmodule Purple.Feed.ItemState do
  use Ecto.Schema

  schema "rss_feed_item_user_state" do
    field :is_read, :boolean
    field :is_hidden, :boolean

    belongs_to :item, Purple.Feed.Item, source: :rss_feed_item_id
    belongs_to :user, Purple.Accounts.User

    timestamps()
  end
end
