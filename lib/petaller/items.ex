defmodule Petaller.Items do
  alias Petaller.Repo
  alias Petaller.Items.{Entry, Item, Tag, ItemTag}

  import Ecto.Query

  def change(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end

  def create(params) do
    %Item{}
    |> Item.changeset(params)
    |> Repo.insert()
  end

  def create_entry(params) do
    %Entry{}
    |> Entry.changeset(params)
    |> Repo.insert()
  end

  def update(%Item{} = item, params) do
    item
    |> Item.changeset(params)
    |> Repo.update()
  end

  def get_with_entries!(id) do
    Item
    |> where([i], i.id == ^id)
    |> Repo.all()
    |> Repo.preload(entries: from(e in Entry, order_by: [desc: e.inserted_at]))
    |> case do
      [item] -> item
      [] -> raise "item not found"
    end
  end

  def get!(id) do
    Item
    |> Repo.get!(id)
  end

  def set_completed_at(%Item{} = item, true) do
    item
    |> Item.changeset(%{
      completed_at: NaiveDateTime.utc_now(),
      is_pinned: false
    })
    |> Repo.update()
  end

  def set_completed_at(%Item{} = item, false) do
    item
    |> Item.changeset(%{completed_at: nil})
    |> Repo.update()
  end

  def set_pinned(%Item{} = item, is_pinned) do
    item
    |> Item.changeset(%{is_pinned: is_pinned})
    |> Repo.update()
  end

  def list_pinned() do
    Item
    |> where([i], i.is_pinned == true)
    |> order_by(asc: :priority, desc: :updated_at)
    |> Repo.all()
  end

  def list_incomplete() do
    Item
    |> where([i], is_nil(i.completed_at))
    |> where([i], i.is_pinned == false)
    |> order_by(asc: :priority, desc: :inserted_at)
    |> Repo.all()
  end

  def list_complete() do
    Item
    |> where([i], not is_nil(i.completed_at))
    |> where([i], i.is_pinned == false)
    |> order_by(desc: :completed_at)
    |> Repo.all()
  end

  def delete!(%Item{} = item) do
    Repo.transaction(fn ->
      Entry
      |> where([e], e.item_id == ^item.id)
      |> Repo.delete_all()

      Repo.delete(item)
    end)
  end
end
