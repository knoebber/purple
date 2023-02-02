defmodule PurpleWeb.RunLive.Show do
  alias Purple.Activities
  alias Purple.Activities.Run
  import PurpleWeb.RunLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🏃"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => run_id}) do
    run = Activities.get_run(run_id)

    if run do
      Run.to_string(run)
    end
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    run = Activities.get_run!(id)

    run_rows =
      run.description
      |> String.split("\n")
      |> length()

    {
      :noreply,
      socket
      |> assign(:page_title, Run.to_string(run))
      |> assign(:run, run)
      |> assign(:run_rows, run_rows + 1)
      |> assign_fancy_link_map(run.description)
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link patch={~p"/runs"}>Runs</.link>
      / <%= "#{@run.id}" %>
    </h1>
    <.section class="mt-2 mb-2">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <strong>
            <%= Run.to_string(@run) %>
          </strong>
          <span>|</span>
          <%= if @live_action == :edit do %>
            <strong>Edit Run</strong>
            <span>|</span>
            <.link patch={~p"/runs/#{@run.id}"} replace={true}>
              Cancel
            </.link>
          <% else %>
            <.link patch={~p"/runs/#{@run.id}/edit"} replace={true}>
              Edit
            </.link>
          <% end %>
        </div>
        <i>
          <%= Purple.Date.format(@run.date) %>
        </i>
      </div>
      <%= if @live_action == :edit do %>
        <div class="m-2 p-2 border border-purple-500 bg-purple-50 rounded">
          <.live_component
            module={PurpleWeb.RunLive.FormComponent}
            id={@run.id}
            action={@live_action}
            rows={@run_rows}
            run={@run}
            return_to={~p"/runs/#{@run.id}"}
          />
        </div>
      <% else %>
        <.markdown content={@run.description} link_type={:run} fancy_link_map={@fancy_link_map} />
      <% end %>
    </.section>
    """
  end
end
