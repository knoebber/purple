defmodule Purple.Feed.Item do 

  use Ecto.Schema

	schema "rss_feed_items" do
    field :link, :string
    field :title, :string
    field :description, :string, default: ""

    belongs_to :source, Purple.Feed.Source, source: :rss_feed_id

    timestamps()
  end
end