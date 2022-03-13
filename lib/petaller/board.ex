defmodule Petaller.Board do
  alias Petaller.Repo
  alias Petaller.Board.{ItemEntry, Item}

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
    Item
    |> Repo.get!(id)
  end

  def get_item_entries(item_id) do
    ItemEntry
    |> where([ie], ie.item_id == ^item_id)
    |> Repo.all()
  end

  def get_item_with_entries!(item_id) do
    Item
    |> where([i], i.id == ^item_id)
    |> Repo.all()
    |> Repo.preload(entries: from(e in ItemEntry, order_by: [desc: e.inserted_at]))
    |> case do
      [item] -> item
      [] -> raise "item not found"
    end
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

  def delete_item!(%Item{} = item) do
    Repo.transaction(fn ->
      ItemEntry
      |> where([e], e.item_id == ^item.id)
      |> Repo.delete_all()

      Repo.delete(item)
    end)
  end
end
