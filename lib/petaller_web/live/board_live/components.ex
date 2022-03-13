defmodule PetallerWeb.BoardLive.Components do
  use PetallerWeb, :component

  def toggle_complete(assigns) do
    ~H"""
    <%= link(if(@item.completed_at, do: "Set Incomplete", else: "Set Complete"),
      phx_click: "toggle_complete",
      phx_value_id: @item.id,
      to: "#"
    ) %>
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
          <th></th>
          <th></th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <%= for item <- @items do %>
          <tr>
            <td>
              <%= live_redirect(item.id, to: Routes.board_show_item_path(@socket, :show_item, item)) %>
            </td>
            <td>
              <%= live_patch(item.description, to: Routes.board_index_path(@socket, :edit_item, item)) %>
            </td>
            <td>
              <%= live_patch(item.priority, to: Routes.board_index_path(@socket, :edit_item, item)) %>
            </td>
            <td>
              <%= format_date(item.inserted_at) %>
            </td>
            <td>
              <%= link("📌",
                phx_click: "toggle_pin",
                phx_value_id: item.id,
                to: "#"
              ) %>
            </td>
            <td>
              <.toggle_complete item={item} />
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
