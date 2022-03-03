defmodule PetallerWeb.ItemLive.Components do
  use Phoenix.Component

  def set_completed_at(assigns) do
    ~H"""
    <%= if @item.completed_at do %>
      Set incomplete
    <% else %>
      Set complete
    <% end %>
    """
  end

  def toggle_pin(assigns) do
    ~H"""
    <%= if assigns.item.is_pinned do %>
      unpin 📌
    <% else %>
      pin 📌
    <% end %>
    """
  end

  def delete_item(assigns) do
    ~H"""
    DELETE <%= @item.id %>
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
              show (live redirect) <%= item.id %>
            </td>
            <td>
              <%= item.description %>
            </td>
            <td>
              <%= item.priority %>
            </td>
            <td>
              <%= item.inserted_at %>
            </td>
            <td>
              <.toggle_pin item={item} />
            </td>
            <td>
              <.set_completed_at item={item} />
            </td>
            <td>
              <.delete_item item={item} />
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
