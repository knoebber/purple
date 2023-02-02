defmodule Purple.Feed.Item do
  import Ecto.Changeset
  use Ecto.Schema

  schema "rss_feed_items" do
    field :link, :string
    field :title, :string
    field :description, :string, default: ""
    field :pub_date, :naive_datetime

    belongs_to :source, Purple.Feed.Source, source: :rss_feed_id

    timestamps()
  end

  def changeset(item) do
    item
    |> change()
    |> unique_constraint([:link], name: "rss_feed_items_link_index")
  end
end
