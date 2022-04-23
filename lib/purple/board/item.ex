defmodule Purple.Board.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :description, :string
    field :priority, :integer, default: 3
    field :completed_at, :naive_datetime
    field :is_pinned, :boolean, default: false
    field :show_files, :boolean, default: false

    timestamps()

    has_many :entries, Purple.Board.ItemEntry
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.ItemTag
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :description,
      :priority,
      :completed_at,
      :is_pinned,
      :show_files
    ])
    |> validate_required([
      :description,
      :priority
    ])
  end
end
