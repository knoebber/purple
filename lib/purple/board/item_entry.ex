defmodule Purple.Board.ItemEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_entries" do
    field :content, :string, default: ""
    field :is_collapsed, :boolean, default: false
    field :sort_order, :integer, default: 0

    belongs_to :item, Purple.Board.Item

    timestamps()
  end

  def changeset(item_entry, attrs) do
    item_entry
    |> cast(attrs, [:content, :is_collapsed, :sort_order, :item_id])
    |> validate_required([:content])
    |> assoc_constraint(:item)
  end
end
