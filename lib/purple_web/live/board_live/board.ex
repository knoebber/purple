defmodule PurpleWeb.BoardLive.Board do
  @moduledoc """
  Live view for viewing items in a board
  """

  alias Purple.Board
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  defp assign_items(socket, user_board) do
    status_map = Board.get_user_board_item_status_map(user_board)

    socket
    |> stream(:todo_items, status_map.todo)
    |> stream(:done_items, status_map.done)
    |> stream(:info_items, status_map.info)
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🧱"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"user_board_id" => board_id}) do
    user_board = Board.get_user_board(board_id)

    case user_board do
      nil -> nil
      _ -> user_board.name
    end
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign_side_nav()
      |> stream_configure(:todo_items, dom_id: &"js-item-#{&1.id}")
      |> stream_configure(:done_items, dom_id: &"js-item-#{&1.id}")
      |> stream_configure(:info_items, dom_id: &"js-item-#{&1.id}")
    }
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    user_board = Board.get_user_board!(Purple.int_from_map!(params, "user_board_id"))

    {
      :noreply,
      socket
      |> assign(:page_title, user_board.name)
      |> assign(:user_board, user_board)
      |> assign_items(user_board)
    }
  end

  defp set_item_status(nil) do
    nil
  end

  defp set_item_status(%{"id" => item_dom_id, "status" => status_str}) do
    [_, _, item_id_str] = String.split(item_dom_id, "-")
    item = Board.get_item(item_id_str)

    if item do
      Board.update_item(item, %{
        "status" =>
          case status_str do
            "info" -> :INFO
            "done" -> :DONE
            "todo" -> :TODO
          end
      })
    end
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save_item_order",
        %{
          "new_status" => new_status,
          "sort_order" => sort_order_map
        },
        socket
      ) do
    dbg(new_status)
    set_item_status(new_status)
    {:noreply, socket}
  end

  defp item(assigns) do
    ~H"""
    <.section :for={{dom_id, item} <- @stream} id={dom_id} class="mb-2 cursor-move js-sortable-item">
      <div class="bg-purple-300">
        <h2 class="ml-2 mb-2 inline">
          <.link navigate={~p"/board/item/#{item.id}"}>
            <%= item.description %>
          </.link>
        </h2>
      </div>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mb-2 flex gap-4">
      <.link navigate={item_create_path(@user_board.id)}>
        <.button type="button">Add Item</.button>
      </.link>
      <h1 class="mb-2"><%= @page_title %></h1>
    </div>
    <div class="grid grid-cols-3 gap-4 ">
      <div class="col-start-1 text-center">
        <h2>TODO</h2>
      </div>
      <div class="col-start-2 text-center">
        <h2>DONE</h2>
      </div>
      <div class="col-start-3 text-center">
        <h2>INFO</h2>
      </div>
      <div
        class="col-start-1 js-status-todo"
        data-sortable-group="items"
        id="js-sortable-todo"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.todo_items} />
      </div>
      <div
        class="col-start-2 js-status-done"
        data-sortable-group="items"
        id="js-sortable-done"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.done_items} />
      </div>
      <div
        class="col-start-3 js-status-info"
        data-sortable-group="items"
        id="js-sortable-info"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.info_items} />
      </div>
    </div>
    """
  end
end
