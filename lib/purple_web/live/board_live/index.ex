defmodule PurpleWeb.BoardLive.Index do
  @moduledoc """
  Index page for board
  """

  use PurpleWeb, :live_view
  import PurpleWeb.BoardLive.BoardHelpers
  import Purple.Filter
  alias Purple.Board

  @filter_types %{
    show_done: :boolean
  }

  defp assign_data(socket) do
    assigns = socket.assigns
    user_board = assigns.user_board

    saved_tag_names =
      user_board.tags
      |> Purple.maybe_list()
      |> Enum.map(& &1.name)

    filter =
      make_filter(
        socket.assigns.query_params,
        %{
          show_done: user_board.show_done
        },
        @filter_types
      )

    filter =
      if is_nil(Map.get(filter, :tag)) and length(saved_tag_names) > 0 do
        Map.put(filter, :tag, saved_tag_names)
      else
        filter
      end

    tag_options =
      case saved_tag_names do
        [] -> Purple.Tags.make_tag_choices(:item)
        _ -> []
      end

    socket
    |> assign(:editable_item, nil)
    |> assign(:filter, filter)
    |> assign(:items, Board.list_items(filter))
    |> assign(
      :page_title,
      if(user_board.name == "", do: "Default Board", else: user_board.name)
    )
    |> assign(:tag_options, tag_options)
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    board_id = Purple.int_from_map(params, "user_board_id")

    user_board =
      if board_id do
        Board.get_user_board!(board_id)
      else
        %Board.UserBoard{name: "All Items", show_done: true}
      end

    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign(:user_board, user_board)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => filter_params}, socket) do
    {
      :noreply,
      push_patch(
        socket,
        to: index_path(socket.assigns.user_board.id, filter_params),
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.pin_item!(item, !item.is_pinned)
    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.set_item_complete!(item, item.completed_at == nil)
    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("edit_item", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editable_item, Board.get_item!(id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.delete_item!(Board.get_item!(id))

    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <%= if @editable_item do %>
      <.modal title={@page_title} return_to={index_path(@user_board.id, @query_params)}>
        <.live_component
          module={PurpleWeb.BoardLive.UpdateItem}
          id={@editable_item.id}
          item={@editable_item}
          return_to={index_path(@user_board.id, @query_params)}
        />
      </.modal>
    <% end %>
    <.filter_form :let={f}>
      <%= live_redirect(to: item_create_path(@user_board.id)) do %>
        <button class="btn">Create</button>
      <% end %>
      <%= text_input(
        f,
        :query,
        placeholder: "Search...",
        phx_debounce: "200",
        value: Map.get(@filter, :query, "")
      ) %>
      <%= if length(@tag_options) > 0 do %>
        <%= select(
          f,
          :tag,
          @tag_options,
          value: Map.get(@filter, :tag, "")
        ) %>
      <% end %>
      <.page_links
        filter={@filter}
        first_page={index_path(@user_board.id, first_page(@filter))}
        num_rows={length(@items)}
      />
    </.filter_form>
    <div class="w-full overflow-auto">
      <.table
        filter={@filter}
        get_route={fn new_filter -> index_path(@user_board.id, new_filter) end}
        rows={@items}
      >
        <:col :let={item} label="Item" order_col="id">
          <%= live_redirect(item.id,
            to: Routes.board_show_item_path(@socket, :show, item)
          ) %>
        </:col>
        <:col :let={item} label="Description" order_col="description">
          <%= live_redirect(item.description,
            to: Routes.board_show_item_path(@socket, :show, item)
          ) %>
        </:col>
        <:col :let={item} label="Priority" order_col="priority">
          <%= item.priority %>
        </:col>
        <:col :let={item} label="Status" order_col="status">
          <%= if item.status == :INFO  do %>
            INFO
          <% else %>
            <input
              type="checkbox"
              checked={item.status == :DONE}
              phx-click="toggle_complete"
              phx-value-id={item.id}
            />
          <% end %>
        </:col>
        <:col :let={item} label="Last Activity" order_col="last_active_at">
          <%= format_date(item.last_active_at) %>
        </:col>
        <:col :let={item} label="">
          <.link
            class={if(!item.is_pinned, do: "opacity-30")}
            phx-click="toggle_pin"
            phx-value-id={item.id}
            href="#"
          >
            📌
          </.link>
        </:col>
        <:col :let={item} label="">
          <.link href="#" phx-click="edit_item" phx-value-id={item.id}>Edit</.link>
        </:col>
        <:col :let={item} label="">
          <.link href="#" phx-click="delete" phx-value-id={item.id} data-confirm="Are you sure?">
            Delete
          </.link>
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={index_path(@user_board.id, first_page(@filter))}
        next_page={index_path(@user_board.id, next_page(@filter))}
        num_rows={length(@items)}
      />
    </div>
    """
  end
end
