defmodule Petaller.Items do
  alias Petaller.Repo
  alias Petaller.{Item,ItemEntry}
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
    # TODO: catch pattern match error here when not found
    [item] = Item
    |> where([i], i.id == ^id)
    |> Repo.all
    |> Repo.preload(:entries)
    item
  end

  def set_completed_at(id, is_complete) do
    Item
    |> Repo.get(id)
    |> Item.changeset(%{completed_at: (if is_complete do NaiveDateTime.utc_now else nil end)})
    |> Repo.update
  end

  def list_incomplete() do
    Item
    |> where([i], is_nil(i.completed_at))
    |> order_by(:priority)
    |> Repo.all
  end

  def list_complete() do
    Item
    |> where([i], not is_nil(i.completed_at))
    |> order_by(desc: :completed_at)
    |> Repo.all
  end

  def delete(id) do
    Item
    |> Repo.get(id)
    |> Repo.delete
  end
end
