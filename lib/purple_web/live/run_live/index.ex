defmodule PurpleWeb.RunLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Activities
  alias Purple.Activities.Run

  defp index_path(params, new_params = %{}) do
    Routes.run_index_path(PurpleWeb.Endpoint, :index, Map.merge(params, new_params))
  end

  defp index_path(params, :new), do: index_path(params, %{action: "new"})
  defp index_path(params, :edit, run_id), do: index_path(params, %{action: "edit", id: run_id})

  defp index_path(params) do
    index_path(
      Map.reject(params, fn {key, _} -> key in ["action", "id"] end),
      %{}
    )
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

  defp apply_action(socket, _, _) do
    socket
    |> assign(:page_title, "Runs")
    |> assign(:run, nil)
  end

  defp assign_runs(socket, params \\ %{}) do
    socket
    |> assign(:runs, Activities.list_runs(Map.get(params, "tag", "")))
    |> assign(:weekly_total, Activities.sum_miles_in_current_week())
  end

  defp get_action(%{"action" => "edit", "id" => _}), do: :edit
  defp get_action(%{"action" => "new"}), do: :new
  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    action = get_action(params)

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign_runs(params)
      |> apply_action(action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign_runs(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex">
      <h1>Runs</h1>
      <%= live_patch(
        to: index_path(@params, :new),
        class: "text-xl self-end ml-1 mr-1")
    do %>
        <button>➕</button>
      <% end %>
      <i class="self-end">
        <%= @weekly_total %> this week
      </i>
    </div>

    <%= if @action in [:new, :edit] do %>
      <.modal return_to={index_path(@params)} title={@page_title}>
        <.live_component
          module={PurpleWeb.RunLive.FormComponent}
          id={@run.id || :new}
          action={@action}
          run={@run}
          return_to={index_path(@params)}
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
              <%= live_patch("Edit", to: index_path(@params, :edit, run.id)) %>
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
