defmodule Purple.Board.Item do
  @moduledoc """
  Model for items
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :completed_at, :naive_datetime
    field :description, :string
    field :last_active_at, :naive_datetime
    field :show_files, :boolean, default: false
    field :status, Ecto.Enum, values: [:TODO, :INFO, :DONE], default: :TODO

    field :combined_checkbox_map, :map, virtual: true, default: %{}
    field :combined_entry_content, :string, virtual: true, default: nil

    timestamps()

    has_many :entries, Purple.Board.ItemEntry
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.ItemTag
  end

  def set_combined_entry_content(%__MODULE__{} = item, should_omit_collapsed \\ false) do
    Map.put(
      item,
      :combined_entry_content,
      Enum.reduce(
        Map.get(item, :entries, []),
        "",
        fn entry, result ->
          if should_omit_collapsed and entry.is_collapsed do
            result
          else
            entry.content <> "\n\n" <> result
          end
        end
      )
    )
  end

  def sort_entries(%__MODULE__{entries: entries} = item) when is_list(entries) do
    Map.put(
      item,
      :entries,
      Enum.sort(
        entries,
        &(&1.sort_order <= &2.sort_order)
      )
    )
  end

  def set_entry_checkbox_maps(%__MODULE__{entries: entries} = item) when is_list(entries) do
    Map.put(
      item,
      :entries,
      Enum.map(
        entries,
        &Purple.Board.ItemEntry.set_checkbox_map/1
      )
    )
  end

  def set_combined_checkbox_map(%__MODULE__{entries: entries} = item)
      when is_list(entries) do
    item = set_entry_checkbox_maps(item)

    item
    |> Map.put(
      :combined_checkbox_map,
      Enum.reduce(
        item.entries,
        %{},
        fn entry, acc -> Map.merge(entry.checkbox_map, acc) end
      )
    )
  end

  defp set_completed_at(changeset) do
    case fetch_change(changeset, :status) do
      {:ok, :DONE} ->
        put_change(
          changeset,
          :completed_at,
          Purple.Date.utc_now()
        )

      _ ->
        changeset
    end
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:description, :status])
    |> cast_assoc(:entries, with: &Purple.Board.ItemEntry.changeset/2)
    |> validate_required([:description, :status])
    |> set_completed_at()
  end
end
