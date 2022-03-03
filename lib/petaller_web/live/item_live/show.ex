defmodule PetallerWeb.ItemLive.Show do
  use PetallerWeb, :live_view

  import PetallerWeb.ItemLive.Components

  alias Petaller.Items

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Item #{id}")
     |> assign(:run, Items.get!(id))}
  end

  defp page_title(:show), do: "Show Item"
  defp page_title(:edit), do: "Edit Item"
end
