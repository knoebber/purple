defmodule Petaller.Items do
  alias Petaller.Items.Item
  alias Petaller.Repo
  import Ecto.Query

  def get_item(id) do
    Repo.get(Item, id)
  end

  def list_items() do
    query = Item |> order_by(desc: :id)
    Repo.all(query)
  end

  def delete_item(id) do
    item = Repo.get(Item, id)
    Repo.delete(item)
  end

  def create_item(params) do
    %Item{}
    |> Item.changeset(params)
    |> Repo.insert()
  end
end
