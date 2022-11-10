defmodule PurpleWeb.RunLive.Index do
  @moduledoc """
  Index page for runs
  """

  use PurpleWeb, :live_view

  import PurpleWeb.RunLive.RunHelpers
  import Purple.Filter

  alias Purple.Activities
  alias Purple.Activities.Run

  defp assign_data(socket) do
    filter = make_filter(socket.assigns.query_params)

    socket
    |> assign(:page_title, "Runs")
    |> assign(:editable_run, nil)
    |> assign(:filter, filter)
    |> assign(:runs, Activities.list_runs(filter))
    |> assign(:weekly_total, Activities.sum_miles_in_current_week())
    |> assign(:total, Activities.sum_miles(filter))
    |> assign(:tag_options, Purple.Tags.make_tag_choices(:run))
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => filter_params}, socket) do
    {
      :noreply,
      push_patch(
        socket,
        to: index_path(filter_params),
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("edit_run", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editable_run, Activities.get_run!(id))}
  end

  @impl Phoenix.LiveView
  def handle_event("create_run", _, socket) do
    last_run =
      case socket.assigns.runs do
        [last_run | _] -> last_run
        _ -> %Run{miles: 0, description: ""}
      end

    last_tags = Purple.Tags.extract_tags(last_run)

    {
      :noreply,
      assign(
        socket,
        :editable_run,
        %Run{
          miles: last_run.miles,
          description: Enum.map_join(last_tags, " ", &("#" <> &1))
        }
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Activities.get_run!()
    |> Activities.delete_run()

    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mb-2 flex">
      <h1><%= @page_title %></h1>
      <i class="ml-2 self-center">
        <%= @weekly_total %> this week, <%= @total %> displayed
      </i>
    </div>
    <.modal :if={@editable_run} return_to={index_path(@query_params)} title={@page_title}>
      <.live_component
        id={@editable_run.id || :new}
        module={PurpleWeb.RunLive.RunForm}
        return_to={index_path(@query_params)}
        rows={3}
        run={@editable_run}
      />
    </.modal>
    <.filter_form :let={f}>
      <%= link(phx_click: "create_run", to: "#") do %>
        <button class="btn">Create</button>
      <% end %>
      <%= text_input(
        f,
        :query,
        placeholder: "Search...",
        phx_debounce: "200",
        value: Map.get(@filter, :query, "")
      ) %>
      <%= select(
        f,
        :tag,
        @tag_options,
        value: Map.get(@filter, :tag, "")
      ) %>
      <.page_links
        filter={@filter}
        first_page={index_path(first_page(@filter))}
        next_page={index_path(next_page(@filter))}
        num_rows={length(@runs)}
      />
    </.filter_form>

    <div class="w-full overflow-auto">
      <.table rows={@runs} get_route={&index_path/1} filter={@filter}>
        <:col :let={run} label="Miles" order_col="miles">
          <%= live_redirect(run.miles, to: Routes.run_show_path(@socket, :show, run)) %>
        </:col>
        <:col :let={run} label="Duration" order_col="seconds">
          <%= Run.format_duration(run.hours, run.minutes, run.minute_seconds) %>
        </:col>
        <:col :let={run} label="Pace">
          <%= Run.format_pace(run.miles, run.seconds) %>
        </:col>
        <:col :let={run} label="Date" order_col="date">
          <%= Purple.Date.format(run.date, :dayname) %>
        </:col>
        <:col :let={run} label="">
          <%= link("✏️", phx_click: "edit_run", phx_value_id: run.id, to: "#") %>
        </:col>
        <:col :let={run} label="">
          <%= link("❌",
            phx_click: "delete",
            phx_value_id: run.id,
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={index_path(first_page(@filter))}
        next_page={index_path(next_page(@filter))}
        num_rows={length(@runs)}
      />
    </div>
    """
  end
end
