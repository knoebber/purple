defmodule PurpleWeb.RunLive.Show do
  use PurpleWeb, :live_view

  import PurpleWeb.RunLive.RunHelpers

  alias Purple.Activities

  defp page_title(:show), do: "Show Run"
  defp page_title(:edit), do: "Edit Run"

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
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:run, run)
      |> assign(:run_rows, run_rows + 1)
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
      <.link patch={Routes.run_index_path(@socket, :index)}>Runs</.link>
      / <%= "#{@run.id}" %>
    </h1>
    <section class="mt-2 mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <strong>
            <%= @run.miles %> miles@<%= format_pace(@run.miles, @run.seconds) %>
          </strong>
          <span>|</span>
          <%= if @live_action == :edit do %>
            <strong>Edit Item</strong>
            <span>|</span>
            <.link patch={Routes.run_show_path(@socket, :show, @run)}>
              Cancel
            </.link>
          <% else %>
            <.link patch={Routes.run_show_path(@socket, :edit, @run)}>
              Edit
            </.link>
          <% end %>
        </div>
        <i>
          <%= format_date(@run.date) %>
        </i>
      </div>
      <%= if @live_action == :edit do %>
        <div class="m-2 p-2 border border-purple-500 bg-purple-50 rounded">
          <.live_component
            module={PurpleWeb.RunLive.RunForm}
            id={@run.id}
            action={@live_action}
            rows={@run_rows}
            run={@run}
            return_to={Routes.run_show_path(@socket, :show, @run)}
          />
        </div>
      <% else %>
        <div class="markdown-content">
          <%= markdown(@run.description, :run) %>
        </div>
      <% end %>
    </section>
    """
  end
end
