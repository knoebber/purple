defmodule Purple.Board.Item do
  @moduledoc """
  Model for items
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :completed_at, :naive_datetime
    field :description, :string
    field :is_pinned, :boolean, default: false
    field :last_active_at, :naive_datetime
    field :priority, :integer, default: 3
    field :show_files, :boolean, default: false
    field :status, Ecto.Enum, values: [:TODO, :INFO, :DONE], default: :TODO

    timestamps()

    has_many :entries, Purple.Board.ItemEntry
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.ItemTag
  end

  defp set_completed_at(changeset) do
    case fetch_change(changeset, :status) do
      {:ok, :DONE} ->
        put_change(
          changeset,
          :completed_at,
          Purple.utc_now()
        )

      _ ->
        changeset
    end
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :last_active_at,
      :completed_at,
      :description,
      :is_pinned,
      :priority,
      :show_files,
      :status
    ])
    |> cast_assoc(:entries, with: &Purple.Board.ItemEntry.changeset/2)
    |> validate_required([
      :description,
      :priority,
      :status
    ])
    |> set_completed_at
  end
end
