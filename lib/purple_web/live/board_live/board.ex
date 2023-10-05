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
    items_for_markdown_render = status_map.todo ++ status_map.info

    fancy_link_map =
      items_for_markdown_render
      |> Enum.reduce("", fn item, all_markdown ->
        item.combined_entry_content <> "\n\n" <> all_markdown
      end)
      |> PurpleWeb.FancyLink.build_fancy_link_map()

    socket
    |> stream(:todo_items, status_map.todo, reset: true)
    |> stream(:done_items, status_map.done, reset: true)
    |> stream(:info_items, status_map.info, reset: true)
    |> assign(:fancy_link_map, fancy_link_map)
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
    dom_id = &"js-item-#{&1.id}"

    {
      :ok,
      socket
      |> assign_side_nav()
      |> stream_configure(:todo_items, dom_id: dom_id)
      |> stream_configure(:done_items, dom_id: dom_id)
      |> stream_configure(:info_items, dom_id: dom_id)
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

  defp parse_dom_id(dom_id) do
    [_, _, item_id_str] = String.split(dom_id, "-")
    Purple.parse_int!(item_id_str)
  end

  defp set_item_status(nil) do
    nil
  end

  defp set_item_status(%{"id" => item_dom_id, "status" => status_str}) do
    item = Board.get_item(parse_dom_id(item_dom_id))

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
  def handle_event("toggle-checkbox", %{"id" => id}, socket) do
    checkbox = Board.get_entry_checkbox!(id)
    Board.set_checkbox_done(checkbox, !checkbox.is_done)
    {:noreply, assign_items(socket, socket.assigns.user_board)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle-done", _, socket) do
    user_board = socket.assigns.user_board

    {:ok, _} =
      Board.update_user_board(user_board, %{
        "show_done" => !user_board.show_done,
        "tags" => user_board.tags
      })

    user_board = Board.get_user_board!(user_board.id)

    {
      :noreply,
      socket
      |> assign(:user_board, user_board)
      |> assign_items(user_board)
    }
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
    set_item_status(new_status)

    get_ids = fn key ->
      Map.get(sort_order_map, key, [])
    end

    params = %{
      info: Enum.map(get_ids.("infoIds"), &parse_dom_id/1),
      todo: Enum.map(get_ids.("todoIds"), &parse_dom_id/1)
    }

    params =
      if socket.assigns.user_board.show_done do
        Map.put(params, :done, Enum.map(get_ids.("doneIds"), &parse_dom_id/1))
      else
        params
      end

    user_board =
      Board.update_user_board_sort_order(
        socket.assigns.user_board,
        params
      )

    {:noreply, assign_items(socket, user_board)}
  end

  defp item_markdown(%{item: %{status: :DONE}} = assigns), do: ~H""

  defp item_markdown(%{item: %{status: :INFO}} = assigns) do
    ~H"""
    <.markdown
      content={@item.combined_entry_content}
      render_type={:non_checkbox_list_only}
      fancy_link_map={@fancy_link_map}
    />
    """
  end

  defp item_markdown(%{item: %{status: :TODO}} = assigns) do
    ~H"""
    <.markdown
      content={@item.combined_entry_content}
      render_type={:checkbox_list_only}
      fancy_link_map={@fancy_link_map}
      checkbox_map={@item.combined_checkbox_map}
    />
    """
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
      <.item_markdown item={item} fancy_link_map={@fancy_link_map} />
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
    <div
      :if={!@user_board.show_done}
      class="flex justify-end js-status-done"
      data-sortable-group="items"
      id="js-sortable-done-hole"
      phx-hook="BoardSortable"
    >
      Done Hole&nbsp;<.link href="#" phx-click="toggle-done">️🌚</.link>
    </div>
    <div class="grid gap-4">
      <div class="col-start-1 text-center">
        <h2>TODO</h2>
      </div>
      <div class="col-start-2 text-center">
        <h2>INFO</h2>
      </div>
      <div :if={@user_board.show_done} class="col-start-3 text-center">
        <h2>
          DONE <.link href="#" phx-click="toggle-done">🌞️</.link>
        </h2>
      </div>
      <div
        class="col-start-1 js-status-todo"
        data-sortable-group="items"
        id="js-sortable-todo"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.todo_items} fancy_link_map={@fancy_link_map} />
      </div>
      <div
        class="col-start-2 js-status-info"
        data-sortable-group="items"
        id="js-sortable-info"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.info_items} fancy_link_map={@fancy_link_map} />
      </div>
      <div
        :if={@user_board.show_done}
        class="col-start-3 js-status-done"
        data-sortable-group="items"
        id="js-sortable-done"
        phx-hook="BoardSortable"
        phx-update="stream"
      >
        <.item stream={@streams.done_items} fancy_link_map={@fancy_link_map} />
      </div>
    </div>
    """
  end
end
