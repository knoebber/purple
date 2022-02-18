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

  def list_completed() do
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
