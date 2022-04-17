defmodule PurpleWeb.RunLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Activities
  alias Purple.Activities.Run

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Run")
    |> assign(:run, Activities.get_run!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Run")
    |> assign(:run, %Run{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Runs")
    |> assign(:run, nil)
  end

  defp list_runs do
    Activities.list_runs()
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    {:noreply,
     socket
     |> assign(:runs, list_runs())
     |> apply_action(socket.assigns.live_action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign(socket, :runs, list_runs())}
  end
end
