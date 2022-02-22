defmodule Petaller.Items do
  alias Petaller.Repo
  alias Petaller.{Item, ItemEntry}
  import Ecto.Query

  def create(params) do
    %Item{}
    |> Item.changeset(params)
    |> Repo.insert()
  end

  def create_entry(params) do
    %ItemEntry{}
    |> ItemEntry.changeset(params)
    |> Repo.insert()
  end

  def get(id) do
    Item
    |> where([i], i.id == ^id)
    |> Repo.all()
    |> Repo.preload(:entries)
    |> case do
      [item] -> item
      [] -> raise "item not found"
    end
  end

  def set_completed_at(id, is_complete) do
    Item
    |> Repo.get!(id)
    |> Item.changeset(%{
      completed_at: if(is_complete, do: NaiveDateTime.utc_now(), else: nil),
      is_pinned: false
    })
    |> Repo.update()
  end

  def pin(id, is_pinned) do
    Item
    |> Repo.get!(id)
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

  def delete(id) do
    Repo.transaction(fn ->
      ItemEntry
      |> where([ie], ie.item_id == ^id)
      |> Repo.delete_all()

      Item
      |> Repo.get!(id)
      |> Repo.delete!()
    end)
  end
end
