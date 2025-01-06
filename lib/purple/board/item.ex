defmodule Purple.Board.Item do
  @moduledoc """
  Model for items
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :description, :string
    field :last_active_at, :naive_datetime
    field :show_files, :boolean, default: false

    field :combined_checkbox_map, :map, virtual: true, default: %{}
    field :combined_entry_content, :string, virtual: true, default: nil
    field :status, Ecto.Enum, values: [:TODO, :INFO, :DONE], virtual: true, default: nil

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

  def set_status(%__MODULE__{entries: entries}) when is_list(entries) do
    checkboxes =
      Enum.reduce(entries, [], fn entry, checkboxes ->
        if entry.is_collapsed do
          # checkboxes in collapsed entries aren't considered for status
          checkboxes
        else
          entry.checkboxes <> checkboxes
        end
      end)

    if checkboxes == [] do
      :INFO
    else
      if Enum.all?(checkboxes, & &1.is_done?) do
        :DONE
      else
        :TODO
      end
    end
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

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:description])
    |> cast_assoc(:entries, with: &Purple.Board.ItemEntry.changeset/2)
    |> validate_required([:description])
  end
end
