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
    completed_items = Items.list_complete()
    incomplete_items = Items.list_incomplete()
    changeset = Item.changeset(%Item{}, %{})
    render(conn, "index.html",
      completed_items: completed_items,
      incomplete_items: incomplete_items,
      changeset: changeset
    )
  end

  def show(conn, %{"id" => id}) do
    item = Items.get(id)
    render(conn, "item.html",
      item: item,
      changeset: ItemEntry.changeset(%ItemEntry{}, %{})
    )
  end

  def create(conn, %{"item" => params}) do
    Items.create(params)
    redirect(conn, to: items_path(conn))
  end

  def create_entry(conn, %{"id" => id, "item_entry" => params}) do
    Items.create_entry(params)
    redirect(conn, to: item_path(conn, id))
  end

  def update_completed_at(conn, %{"id" => id}) do
    Items.set_completed_at(id, conn.method == "POST")
    redirect(conn, to: items_path(conn))
  end

  def delete(conn, %{"id" => id}) do
    Items.delete(id)
    redirect(conn, to: items_path(conn))
  end
end
