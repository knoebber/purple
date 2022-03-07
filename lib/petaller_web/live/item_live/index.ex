defmodule PetallerWeb.ItemLive.Index do
  use PetallerWeb, :live_view

  alias Petaller.Items
  alias Petaller.Items.Item
  alias PetallerWeb.ItemLive.Components

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item #{id}")
    |> assign(:item, Items.get!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Items")
    |> assign(:item, nil)
  end

  defp load_items(socket) do
    socket
    |> assign(:complete_items, Items.list_complete())
    |> assign(:incomplete_items, Items.list_incomplete())
    |> assign(:pinned_items, Items.list_pinned())
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_items(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Items.get!(id)
    Items.set_completed_at(item, !item.completed_at)
    {:noreply, load_items(socket)}
  end

  @impl true
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Items.get!(id)
    IO.inspect(item)
    Items.set_pinned(item, !item.is_pinned)
    {:noreply, load_items(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Items.get!(id)
    |> Items.delete!()

    {:noreply, load_items(socket)}
  end
end
