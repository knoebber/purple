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

  def complete(id) do
    item = Repo.get(Item, id)
    item = Ecto.Changeset.change item, completed: true
    Repo.update(item)
  end

  def list() do
    query = Item |> order_by(desc: :id)
    Repo.all(query)
  end

  def delete(id) do
    item = Repo.get(Item, id)
    Repo.delete(item)
  end
end
