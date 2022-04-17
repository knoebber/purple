defmodule PurpleWeb.BoardLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Board
  alias Purple.Board.Item
  alias PurpleWeb.BoardLive.Components

  defp apply_action(socket, :edit_item, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item #{id}")
    |> assign(:item, Board.get_item!(id))
  end

  defp apply_action(socket, :new_item, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Board")
    |> assign(:item, nil)
  end

  defp load_items(socket) do
    socket
    |> assign(:complete_items, Board.list_complete_items())
    |> assign(:incomplete_items, Board.list_incomplete_items())
    |> assign(:pinned_items, Board.list_pinned_items())
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> load_items
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.set_item_complete!(item, !item.completed_at)
    {:noreply, load_items(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.pin_item(item, !item.is_pinned)
    {:noreply, load_items(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.get_item!(id)
    |> Board.delete_item!()

    {:noreply, load_items(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex">
      <%= live_patch(to: Routes.board_index_path(@socket, :new_item), class: "text-xl") do %>
        <h1>Add Item</h1>
      <% end %>
    </div>
    <%= if @live_action in [:new_item, :edit_item] do %>
      <.modal return_to={Routes.board_index_path(@socket, :index)} title={@page_title}>
        <.live_component
          module={PurpleWeb.BoardLive.ItemForm}
          id={@item.id || :new}
          title={@page_title}
          action={@live_action}
          item={@item}
          return_to={Routes.board_index_path(@socket, :index)}
        />
      </.modal>
    <% end %>
    <h2 class="mt-2 mb-2">Pinned</h2>
    <Components.item_table socket={@socket} items={@pinned_items} />
    <h2 class="mt-2 mb-2">Incomplete</h2>
    <Components.item_table socket={@socket} items={@incomplete_items} />
    <h2 class="mt-2 mb-2">Complete</h2>
    <Components.item_table socket={@socket} items={@complete_items} />
    """
  end
end
