defmodule Petaller.Items do
  alias Petaller.Items.Item
  alias Petaller.Repo
  import Ecto.Query

  def create(params) do
    %Item{}
    |> Item.changeset(params)
    |> Repo.insert()
  end

  def get(id) do
    Repo.get(Item, id)
  end

  def set_complete(id, complete) do
    item = Repo.get(Item, id)
    item = Ecto.Changeset.change item, completed: complete
    Repo.update(item)
  end

  def list_incomplete() do
    Item
    |> where(completed: false)
    |> order_by(desc: :id)
    |> Repo.all
  end

  def list_completed() do
    Item
    |> where(completed: true)
    |> order_by(desc: :id)
    |> Repo.all
  end

  def delete(id) do
    Item
    |> Repo.get(id)
    |> Repo.delete
  end
end
