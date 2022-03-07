defmodule PetallerWeb.ItemLive.Show do
  use PetallerWeb, :live_view

  alias Petaller.Items
  alias PetallerWeb.ItemLive.Components

  defp page_title(item_id, :show), do: "Item #{item_id}"
  defp page_title(item_id, :edit), do: "Edit Item #{item_id}"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    IO.inspect(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(id, socket.assigns.live_action))
     |> assign(:item, Items.get_with_entries!(id))}
  end

  @impl true
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Items.get!(id)
    Items.set_completed_at(item, !item.completed_at)
    {:noreply, socket}
  end
end
