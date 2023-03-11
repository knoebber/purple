defmodule PurpleWeb.RunLive.Index do
  @moduledoc """
  Index page for runs
  """

  use PurpleWeb, :live_view

  import PurpleWeb.RunLive.Helpers
  import Purple.Filter

  alias Purple.Activities
  alias Purple.Activities.Run

  defp assign_data(socket) do
    filter = make_filter(socket.assigns.query_params)

    socket
    |> assign(:page_title, "Runs")
    |> assign(:filter, filter)
    |> assign(:runs, Activities.list_runs(filter))
    |> assign(:weekly_total, Activities.sum_miles_in_current_week())
    |> assign(:total, Activities.sum_miles(filter))
    |> assign(:tag_options, Purple.Tags.make_tag_choices(:run))
  end

  defp apply_action(socket, :edit, %{"id" => run_id}) do
    assign(socket, :editable_run, Activities.get_run!(run_id))
  end

  defp apply_action(socket, :create, _) do
    last_run =
      case socket.assigns.runs do
        [last_run | _] -> last_run
        _ -> %Run{miles: 0, description: ""}
      end

    last_tags = Purple.Tags.extract_tags(last_run)

    assign(socket, :editable_run, %Run{
      miles: last_run.miles,
      description: Enum.map_join(last_tags, " ", &("#" <> &1))
    })
  end

  defp apply_action(socket, :index, _) do
    assign(socket, :editable_run, nil)
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign_data()
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => filter_params}, socket) when is_map(filter_params) do
    {
      :noreply,
      push_patch(
        socket,
        to: ~p"/runs?#{filter_params}",
        replace: true
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
    <.modal
      :if={!!@editable_run}
      id="edit-run-modal"
      on_cancel={JS.patch(~p"/runs?#{@filter}", replace: true)}
      show
    >
      <:title><%= Purple.titleize(@live_action) %> Run</:title>
      <.live_component
        id={@editable_run.id || :new}
        module={PurpleWeb.RunLive.FormComponent}
        return_to={~p"/runs?#{@filter}"}
        rows={3}
        run={@editable_run}
      />
    </.modal>
    <.filter_form :let={f}>
      <.link patch={~p"/runs/create?#{@filter}"} replace={true}>
        <.button phx-click="create_run">Create</.button>
      </.link>
      <.input
        field={f[:query]}
        value={Map.get(@filter, :query, "")}
        placeholder="Search..."
        phx-debounce="200"
        class="lg:w-1/4"
      />
      <.input
        field={f[:tag]}
        type="select"
        options={@tag_options}
        value={Map.get(@filter, :tag, "")}
        class=""
      />
      <.page_links
        filter={@filter}
        first_page={~p"/runs?#{first_page(@filter)}"}
        next_page={~p"/runs?#{next_page(@filter)}"}
        num_rows={length(@runs)}
      />
    </.filter_form>
    <div class="w-full overflow-auto">
      <.table rows={@runs} get_route={fn filter -> ~p"/runs?#{filter}" end} filter={@filter}>
        <:col :let={run} label="Miles" order_col="miles">
          <.link navigate={~p"/runs/#{run}"}>
            <%= run.miles %>
          </.link>
        </:col>
        <:col :let={run} label="Duration" order_col="seconds">
          <%= Run.format_duration(run) %>
        </:col>
        <:col :let={run} label="Pace">
          <%= Run.format_pace(run) %>
        </:col>
        <:col :let={run} label="Date" order_col="date">
          <%= Purple.Date.format(run.date, :dayname) %>
        </:col>
        <:col :let={run} label="">
          <.link patch={~p"/runs/edit/#{run}?#{@filter}"} replace={true}>
            ✏️
          </.link>
        </:col>
        <:col :let={run} label="">
          <.link href="#" phx-click="delete" phx-value-id={run.id} data-confirm="Are you sure?">
            ❌
          </.link>
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={~p"/runs?#{first_page(@filter)}"}
        next_page={~p"/runs?#{next_page(@filter)}"}
        num_rows={length(@runs)}
      />
    </div>
    """
  end
end
