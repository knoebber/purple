defmodule PetallerWeb.ItemsController do
  use PetallerWeb, :controller

  alias Petaller.Items
  alias Petaller.Items.Item

  def index(conn, _params) do
    items = Items.list_items()
    changeset = Item.changeset(%Item{}, %{})
    render(conn, "index.html", items: items, changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    Items.create_item(item_params)
    redirect(conn, to: "/items")
  end
end
