defmodule PurpleWeb.RunLive.Index do
  use PurpleWeb, :live_view

  import PurpleWeb.RunLive.RunHelpers

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

  defp apply_action(socket, _, _) do
    socket
    |> assign(:page_title, "Runs")
    |> assign(:run, nil)
  end

  defp assign_runs(socket) do
    runs = Activities.list_runs(socket.assigns.filter.changes)

    socket
    |> assign(:runs, runs)
    |> assign(:weekly_total, Activities.sum_miles_in_current_week())
    |> assign(:total, Activities.sum_miles(runs))
    |> assign(:tag_options, Purple.Filter.make_tag_select_options(:run))
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
      |> assign(:filter, Purple.Filter.make_filter(params))
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign_runs()
      |> apply_action(action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => params}, socket) do
    {:noreply, push_patch(socket, to: index_path(params), replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    run = Activities.get_run!(id)
    {:ok, _} = Activities.delete_run(run)

    {:noreply, assign_runs(socket)}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mb-2 flex">
      <h1>Runs</h1>
      <i class="ml-2 self-center">
        <%= @weekly_total %> this week, <%= @total %> displayed
      </i>
    </div>

    <%= if @action in [:new, :edit] do %>
      <.modal return_to={index_path(@params)} title={@page_title}>
        <.live_component
          action={@action}
          id={@run.id || :new}
          module={PurpleWeb.RunLive.RunForm}
          return_to={index_path(@params)}
          rows={3}
          run={@run}
        />
      </.modal>
    <% end %>
    <.form
      class="table-filters"
      for={@filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      <%= live_patch(to: index_path(@params, :new)) do %>
        <button class="btn">Create</button>
      <% end %>
      <%= text_input(f, :query, placeholder: "Search...", phx_debounce: "200") %>
      <%= select(f, :tag, @tag_options) %>
    </.form>

    <div class="w-full overflow-auto">
      <.table rows={@runs}>
        <:col let={run} label="Miles">
          <%= live_redirect(run.miles, to: Routes.run_show_path(@socket, :show, run)) %>
        </:col>
        <:col let={run} label="Duration">
          <%= format_duration(run.hours, run.minutes, run.minute_seconds) %>
        </:col>
        <:col let={run} label="Pace">
          <%= format_pace(run.miles, run.seconds) %>
        </:col>
        <:col let={run} label="Date">
          <%= format_date(run.date, :dayname) %>
        </:col>
        <:col let={run} label="">
          <%= live_patch("Edit", to: index_path(@params, :edit, run.id)) %>
        </:col>
        <:col let={run} label="">
          <%= link("Delete",
            phx_click: "delete",
            phx_value_id: run.id,
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        </:col>
      </.table>
    </div>
    """
  end
end
