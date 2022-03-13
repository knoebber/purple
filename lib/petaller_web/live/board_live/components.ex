defmodule PetallerWeb.BoardLive.Components do
  use PetallerWeb, :component

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

  def item_table(assigns) do
    ~H"""
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
                to: Routes.board_show_item_path(@socket, :show_item, item)
              ) %>
            </td>
            <td>
              <%= live_redirect(item.description,
                to: Routes.board_show_item_path(@socket, :show_item, item)
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
              <%= live_patch("Edit", to: Routes.board_index_path(@socket, :edit_item, item)) %>
            </td>
            <td>
              <%= link("📌",
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
