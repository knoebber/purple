defmodule PurpleWeb.BoardLive.ItemSearch do
  @moduledoc """
  Index page for board
  """
  alias Purple.Board
  import Purple.Filter
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  defp assign_data(socket) do
    filter = make_filter(socket.assigns.query_params)

    items =
      if filter == %{} do
        # Defaults to an empty page until user sets filter
        []
      else
        filter = Map.put(filter, :show_done, true)
        Board.list_items(filter)
      end

    socket
    |> assign(:filter, filter)
    |> assign(:items, items)
    |> assign(:page_title, "Item Search")
    |> assign(:tag_options, Purple.Tags.make_tag_choices(:item))
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
        to: search_path(nil, filter_params),
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.filter_form :let={f}>
      <.link navigate={item_create_path(nil)}>
        <.button type="button">Create</.button>
      </.link>
      <.input
        field={f[:query]}
        value={Map.get(@filter, :query, "")}
        placeholder="Search..."
        phx-debounce="200"
        class="lg:w-1/4"
      />
      <.input
        :if={length(@tag_options) > 0}
        field={f[:tag]}
        type="select"
        options={@tag_options}
        value={Map.get(@filter, :tag, "")}
        class="lg:w-1/4"
      />
      <.page_links
        filter={@filter}
        first_page={search_path(first_page(@filter))}
        next_page={search_path(next_page(@filter))}
        num_rows={length(@items)}
      />
    </.filter_form>
    <div class="w-full overflow-auto">
      <.table
        filter={@filter}
        get_route={fn new_filter -> search_path(nil, new_filter) end}
        rows={@items}
      >
        <:col :let={item} label="Item" order_col="id">
          <.link navigate={~p"/board/item/#{item}"}><%= item.id %></.link>
        </:col>
        <:col :let={item} label="Description" order_col="description">
          <.link navigate={~p"/board/item/#{item}"}><%= item.description %></.link>
        </:col>
        <:col :let={item} label="Status" order_col="status">
          <%= item.status %>
        </:col>
        <:col :let={item} label="Last Activity" order_col="last_active_at">
          <%= Purple.Date.format(item.last_active_at) %>
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={search_path(nil, first_page(@filter))}
        next_page={search_path(nil, next_page(@filter))}
        num_rows={length(@items)}
      />
    </div>
    """
  end
end
