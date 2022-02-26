defmodule Petaller.Items.ItemTag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_tags" do
    belongs_to :item, Petaller.Items.Item
    belongs_to :tag, Petaller.Items.Tag

    timestamps()
  end

  def changeset(item_tag, attrs) do
    item_tag
    |> cast(attrs, [:item_id, :tag_id])
    |> validate_required([:item_id, :tag_id])
    |> assoc_constraint(:item)
    |> assoc_constraint(:tag)
  end
end
