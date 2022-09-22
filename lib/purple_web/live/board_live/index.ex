defmodule PurpleWeb.BoardLive.Index do
  @moduledoc """
  Index page for board
  """

  use PurpleWeb, :live_view
  import PurpleWeb.BoardLive.BoardHelpers
  import Purple.Filter
  alias Purple.Board
  alias Purple.Board.Item

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
    |> assign(:page_title, if(user_board.name == "", do: "Default Board", else: user_board.name))
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
    <.form
      class="table-filters"
      for={:filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
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
      <%= if current_page(@filter) > 1 do %>
        <%= live_patch(
          "First page",
          to: index_path(@user_board.id, first_page(@filter))
        ) %> &nbsp;
      <% end %>
    </.form>
    <div class="w-full overflow-auto">
      <.table rows={@items}>
        <:col let={item} label="Item">
          <%= live_redirect(item.id,
            to: Routes.board_show_item_path(@socket, :show, item)
          ) %>
        </:col>
        <:col let={item} label="Description">
          <%= live_redirect(item.description,
            to: Routes.board_show_item_path(@socket, :show, item)
          ) %>
        </:col>
        <:col let={item} label="Priority">
          <%= item.priority %>
        </:col>
        <:col let={item} label="Status">
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
        <:col let={item} label="Created">
          <.timestamp model={item} . />
        </:col>
        <:col let={item} label="">
          <%= link("📌",
            class: if(!item.is_pinned, do: "opacity-30"),
            phx_click: "toggle_pin",
            phx_value_id: item.id,
            to: "#"
          ) %>
        </:col>
        <:col let={item} label="">
          <%= link("Edit", phx_click: "edit_item", phx_value_id: item.id, to: "#") %>
        </:col>
        <:col let={item} label="">
          <%= link("Delete",
            phx_click: "delete",
            phx_value_id: item.id,
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        </:col>
      </.table>
      <%= if current_page(@filter) > 1 do %>
        <%= live_patch(
          "First page",
          to: index_path(@user_board.id, first_page(@filter))
        ) %> &nbsp;
      <% end %>
      <%= live_patch(
        "Next page",
        to: index_path(@user_board.id, next_page(@filter))
      ) %>
    </div>
    """
  end
end
