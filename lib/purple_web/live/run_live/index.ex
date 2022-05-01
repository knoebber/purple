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
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign(socket, :runs, list_runs())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex">
      <h1>Runs</h1>
      <%= live_patch(
        to: Routes.run_index_path(@socket, :new),
        class: "text-xl self-end ml-1 mr-1")
    do %>
        <button>➕</button>
      <% end %>
      <i class="self-end">
        <%= Activities.get_miles_in_current_week(@runs) |> Float.round(2) %> this week
      </i>
    </div>

    <%= if @live_action in [:new, :edit] do %>
      <.modal return_to={Routes.run_index_path(@socket, :index)} title={@page_title}>
        <.live_component
          module={PurpleWeb.RunLive.FormComponent}
          id={@run.id || :new}
          action={@live_action}
          run={@run}
          return_to={Routes.run_index_path(@socket, :index)}
        />
      </.modal>
    <% end %>
    <table class="window mt-2">
      <thead class="bg-purple-300">
        <tr>
          <th>Miles</th>
          <th>Duration</th>
          <th>Pace</th>
          <th>Date</th>
          <th></th>
          <th></th>
        </tr>
      </thead>
      <tbody id="runs">
        <%= for run <- @runs do %>
          <tr id={"run-#{run.id}"}>
            <td>
              <%= live_redirect(run.miles, to: Routes.run_show_path(@socket, :show, run)) %>
            </td>
            <td>
              <%= format_duration(run.hours, run.minutes, run.minute_seconds) %>
            </td>
            <td>
              <%= format_pace(run.miles, run.seconds) %>
            </td>
            <td>
              <%= format_date(run.date, :dayname) %>
            </td>
            <td>
              <%= live_patch("Edit", to: Routes.run_index_path(@socket, :edit, run)) %>
            </td>
            <td>
              <%= link("Delete",
                phx_click: "delete",
                phx_value_id: run.id,
                data: [confirm: "Are you sure?"],
                to: "#"
              ) %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
