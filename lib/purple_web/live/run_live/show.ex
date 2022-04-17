defmodule PurpleWeb.RunLive.Show do
  use PurpleWeb, :live_view

  alias Purple.Activities

  defp page_title(:show), do: "Show Run"
  defp page_title(:edit), do: "Edit Run"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:run, Activities.get_run!(id))}
  end
end
