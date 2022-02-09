defmodule PetallerWeb.ItemsController do
  use PetallerWeb, :controller

  alias Petaller.Items
  alias Petaller.Items.Item

  def index(conn, _params) do
    items = Items.list()
    changeset = Item.changeset(%Item{}, %{})
    render(conn, "index.html", items: items, changeset: changeset)
  end

  def get(conn, %{"id" => id}) do
    item = Items.get(id)
    render(conn, "item.html", item: item)
  end

  def create(conn, %{"item" => params}) do
    Items.create(params)
    redirect(conn, to: "/items")
  end

  def complete(conn, %{"id" => id}) do
    Items.complete(id)
    redirect(conn, to: "/items")
  end

  def delete(conn, %{"id" => id}) do
    Items.delete(id)
    redirect(conn, to: "/items")
  end
end
