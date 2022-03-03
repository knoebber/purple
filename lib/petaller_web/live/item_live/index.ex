defmodule PetallerWeb.ItemLive.Index do
  use PetallerWeb, :live_view

  import PetallerWeb.ItemLive.Components

  alias Petaller.Items
  alias Petaller.Items.Item

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:complete_items, Items.list_complete())
     |> assign(:incomplete_items, Items.list_incomplete())
     |> assign(:pinned_items, Items.list_pinned())}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Items.get_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Items")
    |> assign(:run, nil)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign(socket, :runs, list_runs())}
  end

  defp list_runs do
    Activities.list_runs()
  end
end
