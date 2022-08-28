defmodule Purple.Board.EntryCheckbox do
  @moduledoc """
  Model for entry checkboxes
  """

  use Ecto.Schema

  schema "entry_checkboxes" do
    field :description, :string
    field :is_done, :boolean, default: false

    belongs_to :item_entry, Purple.Board.ItemEntry

    timestamps()
  end

  def new(item_entry_id, description)
      when is_integer(item_entry_id) and is_binary(description) and description != "" do
    %__MODULE__{
      description: description,
      item_entry_id: item_entry_id,
      is_done: false
    }
  end
end
