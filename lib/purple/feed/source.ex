defmodule Purple.Feed.Source do
  use Ecto.Schema

  schema "rss_feeds" do
    field :url, :string
    field :title, :string, default: ""

    timestamps()
  end
end
