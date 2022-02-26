defmodule Petaller.Items.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_entries" do
    field :content, :string

    belongs_to :item, Petaller.Items.Item

    timestamps()
  end

  def changeset(item_entry, attrs) do
    item_entry
    |> cast(attrs, [:content, :item_id])
    |> validate_required([:content, :item_id])
    |> assoc_constraint(:item)
  end
end
