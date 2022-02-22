defmodule PetallerWeb.ItemsController do
  use PetallerWeb, :controller

  alias Petaller.{Item, Items, ItemEntry}

  defp items_path(conn) do
    Routes.items_path conn, :index
  end

  defp item_path(conn, id) do
    Routes.items_path conn, :show, id
  end

  def index(conn, _params) do
    render(conn, "index.html",
      changeset: Item.changeset(%Item{}, %{}),
      complete_items: Items.list_complete(),
      incomplete_items: Items.list_incomplete(),
      pinned_items: Items.list_pinned()
    )
  end

  def show(conn, %{"id" => id}) do
    render(conn, "item.html",
      item: Items.get(id),
      changeset: ItemEntry.changeset(%ItemEntry{}, %{})
    )
  end

  def create(conn, %{"item" => params}) do
    Items.create(params)
    redirect(conn, to: items_path(conn))
  end

  def create_entry(conn, %{"id" => id, "item_entry" => params}) do
    Map.put(params, "item_id", id)
    |> Items.create_entry
    redirect(conn, to: item_path(conn, id))
  end

  def update_completed_at(conn, %{"id" => id}) do
    Items.set_completed_at(id, conn.method == "PUT")
    redirect(conn, to: items_path(conn))
  end

  def pin(conn, %{"id" => id}) do
    Items.pin(id, conn.method == "PUT")
    redirect(conn, to: items_path(conn))
  end

  def delete(conn, %{"id" => id}) do
    Items.delete(id)
    redirect(conn, to: items_path(conn))
  end
end
