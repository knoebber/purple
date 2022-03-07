defmodule PetallerWeb.ItemLive.Components do
  import Phoenix.HTML.Link
  alias PetallerWeb.Router.Helpers, as: Routes
  use Phoenix.Component

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
              <%= live_redirect(item.id, to: Routes.item_show_path(@socket, :show, item)) %>
            </td>
            <td>
              <%= live_patch(item.description, to: Routes.item_index_path(@socket, :edit, item)) %>
            </td>
            <td>
              <%= live_patch(item.priority, to: Routes.item_index_path(@socket, :edit, item)) %>
            </td>
            <td>
              <%= item.inserted_at %>
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

  """
  def format_date(naive_dt) do
    DateTime.from_naive!(naive_dt, "Etc/UTC")
    |> DateTime.shift_zone!("America/Anchorage")
    |> Calendar.strftime("%m/%d/%Y %I:%M%P")
  end

  def md(markdown) do
    Earmark.as_html!(markdown)
    |> HtmlSanitizeEx.markdown_html()
    |> raw
  end
  """
end
