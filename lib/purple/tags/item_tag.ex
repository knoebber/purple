defmodule Purple.Tags.ItemTag do
  use Ecto.Schema

  schema "item_tags" do
    belongs_to :item, Purple.Board.Item
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
