defmodule Purple.Board.ItemEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_entries" do
    field :content, :string, default: ""
    field :is_collapsed, :boolean, default: false
    field :sort_order, :integer, default: 0

    field :checkbox_map, :map, virtual: true, default: %{}

    belongs_to :item, Purple.Board.Item
    has_many :checkboxes, Purple.Board.EntryCheckbox, on_replace: :delete_if_exists

    timestamps()
  end

  def set_checkbox_map(%__MODULE__{} = entry) do
    Map.put(
      entry,
      :checkbox_map,
      Enum.reduce(
        entry.checkboxes,
        %{},
        fn checkbox, acc -> Map.put(acc, checkbox.description, checkbox) end
      )
    )
  end

  def changeset(item_entry, attrs \\ %{}) do
    item_entry
    |> cast(attrs, [:content, :is_collapsed, :sort_order])
    |> validate_required([:content])
    |> assoc_constraint(:item)
  end
end
