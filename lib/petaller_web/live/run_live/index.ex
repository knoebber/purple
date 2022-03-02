defmodule PetallerWeb.RunLive.Index do
  use PetallerWeb, :live_view

  alias Petaller.Activities
  alias Petaller.Activities.Run

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:greeting, "Get moving!")
     |> assign(:runs, list_runs())}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

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

  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign(socket, :runs, list_runs())}
  end

  defp list_runs do
    Activities.list_runs()
  end
end
