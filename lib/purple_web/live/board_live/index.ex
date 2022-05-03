defmodule PurpleWeb.BoardLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Board
  alias Purple.Board.Item
  alias PurpleWeb.BoardLive.Components

  defp index_path(params, new_params = %{}) do
    Routes.board_index_path(PurpleWeb.Endpoint, :index, Map.merge(params, new_params))
  end

  defp index_path(params, :new_item) do
    index_path(params, %{action: "new_item"})
  end

  defp index_path(params, :edit_item, item_id) do
    index_path(params, %{action: "edit_item", id: item_id})
  end

  defp index_path(params) do
    index_path(
      Map.reject(params, fn {key, _} -> key in ["action", "id"] end),
      %{}
    )
  end

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

  defp assign_items(socket, params \\ %{}) do
    assign(socket, :items, Board.list_items(Map.get(params, "tag", "")))
  end

  defp get_action(%{"action" => "edit_item", "id" => _}), do: :edit_item
  defp get_action(%{"action" => "new_item"}), do: :new_item
  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    action = get_action(params)

    {
      :noreply,
      socket
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign_items(params)
      |> apply_action(action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.set_item_complete!(item, !item.completed_at)
    {:noreply, assign_items(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.pin_item(item, !item.is_pinned)
    {:noreply, assign_items(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.get_item!(id)
    |> Board.delete_item!()

    {:noreply, assign_items(socket)}
  end

  def toggle_complete(assigns) do
    ~H"""
    <input
      phx-click="toggle_complete"
      phx-value-id={@item.id}
      type="checkbox"
      checked={!!@item.completed_at}
    />
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1>Items</h1>
      <%= live_patch(
        to: index_path(@params, :new_item),
        class: "text-xl self-end ml-1")
      do %>
        <button>➕</button>
      <% end %>
    </div>
    <%= if @action in [:new_item, :edit_item] do %>
      <.modal title={@page_title} return_to={index_path(@params)}>
        <.live_component
          module={PurpleWeb.BoardLive.ItemForm}
          id={@item.id || :new}
          action={@action}
          item={@item}
          return_to={index_path(@params)}
        />
      </.modal>
    <% end %>
    <table class="window">
      <thead class="bg-purple-300">
        <tr>
          <th>Item</th>
          <th>Description</th>
          <th>Priority</th>
          <th>Created</th>
          <th>Complete</th>
          <th></th>
          <th></th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr>
            <td>
              <%= live_redirect(item.id,
                to: Routes.board_show_item_path(@socket, :show, item)
              ) %>
            </td>
            <td>
              <%= live_redirect(item.description,
                to: Routes.board_show_item_path(@socket, :show, item)
              ) %>
            </td>
            <td class="text-center">
              <%= item.priority %>
            </td>
            <td>
              <%= format_date(item.inserted_at) %>
            </td>
            <td class="text-center">
              <.toggle_complete item={item} />
            </td>
            <td>
              <%= live_patch("Edit", to: index_path(@params, :edit_item, item.id)) %>
            </td>
            <td>
              <%= link("📌",
                class: if(!item.is_pinned, do: "opacity-30"),
                phx_click: "toggle_pin",
                phx_value_id: item.id,
                to: "#"
              ) %>
            </td>
            <td>
              <%= link("Delete",
                phx_click: "delete",
                phx_value_id: item.id,
                data: [confirm: "Are you sure?"],
                to: "#"
              ) %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
