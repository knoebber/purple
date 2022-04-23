defmodule Purple.Board do
  alias Purple.Repo
  alias Purple.Board.{ItemEntry, Item}

  import Ecto.Query

  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  def change_item_entry(%ItemEntry{} = entry, attrs \\ %{}) do
    ItemEntry.changeset(entry, attrs)
  end

  def create_item(params) do
    %Item{}
    |> Item.changeset(params)
    |> Repo.insert()
  end

  def create_item_entry(params) do
    %ItemEntry{}
    |> ItemEntry.changeset(params)
    |> Repo.insert()
  end

  def update_item(%Item{} = item, params) do
    item
    |> Item.changeset(params)
    |> Repo.update()
  end

  def update_item_entry(%ItemEntry{} = entry, params) do
    entry
    |> ItemEntry.changeset(params)
    |> Repo.update()
  end

  def get_item!(id) do
    Repo.get!(Item, id)
  end

  def get_item!(id, :entries, :tags) do
      Repo.one!(
        from i in Item,
          join: e in assoc(i, :entries),
          join: t in assoc(i, :tags),
          where: i.id == ^id,
          preload: [entries: e, tags: t]
      )
  end

  def get_item_entries(item_id) do
    ItemEntry
    |> where([ie], ie.item_id == ^item_id)
    |> order_by(asc: :sort_order, desc: :inserted_at)
    |> Repo.all()
  end

  def set_item_complete!(%Item{} = item, true) do
    item
    |> Item.changeset(%{
      completed_at: NaiveDateTime.utc_now()
    })
    |> Repo.update!()
  end

  def set_item_complete!(%Item{} = item, false) do
    item
    |> Item.changeset(%{completed_at: nil})
    |> Repo.update!()
  end

  def pin_item(%Item{} = item, is_pinned) do
    item
    |> Item.changeset(%{is_pinned: is_pinned})
    |> Repo.update()
  end

  def collapse_item_entries(entry_ids, is_collapsed) do
    ItemEntry
    |> where([ie], ie.id in ^entry_ids)
    |> Repo.update_all(set: [is_collapsed: is_collapsed])
  end

  def toggle_show_item_files(item_id, show_files) do
    Item
    |> where([i], i.id == ^item_id)
    |> Repo.update_all(set: [show_files: show_files])
  end

  def save_item_entry_sort_order(entries) do
    Repo.transaction(fn ->
      Enum.each(entries, fn entry ->
        ItemEntry
        |> where([ie], ie.id == ^entry.id)
        |> Repo.update_all(set: [sort_order: entry.sort_order])
      end)
    end)
  end

  def list_pinned_items() do
    Item
    |> where([i], i.is_pinned == true)
    |> order_by(asc: :priority, desc: :updated_at)
    |> Repo.all()
  end

  def list_incomplete_items() do
    Item
    |> where([i], is_nil(i.completed_at))
    |> where([i], i.is_pinned == false)
    |> order_by(asc: :priority, desc: :inserted_at)
    |> Repo.all()
  end

  def list_complete_items() do
    Item
    |> where([i], not is_nil(i.completed_at))
    |> where([i], i.is_pinned == false)
    |> order_by(desc: :completed_at)
    |> Repo.all()
  end

  def delete_entry!(%ItemEntry{} = item_entry) do
    Repo.delete!(item_entry)
  end

  def delete_item!(%Item{} = item) do
    Purple.Uploads.delete_file_uploads_in_item!(item.id)
    Repo.transaction(fn ->
      ItemEntry
      |> where([e], e.item_id == ^item.id)
      |> Repo.delete_all()

      Repo.delete!(item)
    end)
  end
end
