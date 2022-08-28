defmodule Purple.Board.EntryCheckbox do
  @moduledoc """
  Model for entry checkboxes
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "entry_checkboxes" do
    field :description, :string
    field :is_done, :boolean, default: false

    belongs_to :item_entry, Purple.Board.ItemEntry

    timestamps()
  end

  def changeset(entry_checkbox, attrs) do
    entry_checkbox
    |> cast(attrs, [:description, :is_done])
    |> validate_required([:description])
    |> unique_constraint(
      [:item_entry_id, :description],
      message: "checkbox already exists",
      name: "entry_checkboxes_item_entry_id_description_index"
    )
  end
end
