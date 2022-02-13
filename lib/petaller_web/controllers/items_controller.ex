defmodule PetallerWeb.ItemsController do
  use PetallerWeb, :controller

  alias Petaller.Items
  alias Petaller.Items.Item

  def index(conn, _params) do
    completed_items = Items.list_completed()
    incomplete_items = Items.list_incomplete()
    changeset = Item.changeset(%Item{}, %{})
    render(conn, "index.html",
      completed_items: completed_items,
      incomplete_items: incomplete_items,
      changeset: changeset,
    )
  end

  def get(conn, %{"id" => id}) do
    item = Items.get(id)
    render(conn, "item.html", item: item)
  end

  def create(conn, %{"item" => params}) do
    Items.create(params)
    redirect(conn, to: "/items")
  end

  def set_complete(conn, %{"id" => id}) do
    Items.set_complete(id, true)
    redirect(conn, to: "/items")
  end

  def set_incomplete(conn, %{"id" => id}) do
    Items.set_complete(id, false)
    redirect(conn, to: "/items")
  end

  def delete(conn, %{"id" => id}) do
    Items.delete(id)
    redirect(conn, to: "/items")
  end
end
