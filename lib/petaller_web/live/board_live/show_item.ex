defmodule PetallerWeb.BoardLive.Show do
  use PetallerWeb, :live_view

  alias Petaller.Board
  alias PetallerWeb.BoardLive.Components

  defp page_title(item_id, :show), do: "Item #{item_id}"
  defp page_title(item_id, :edit), do: "Edit Item #{item_id}"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    IO.inspect(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(id, socket.assigns.live_action))
     |> assign(:item, Board.get_item_with_entries!(id))}
  end

  @impl true
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    item = Board.get_item!(id)
    Board.set_item_complete(item, !item.completed_at)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>

    <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <div class="flex justify-between">
        <Components.toggle_complete item={@item} />
        <i>
          <%= format_date(@item.inserted_at) %>
        </i>
      </div>
      <div>
        <strong>
          <%= @item.description %>
        </strong>
      </div>
      <div>
        <%= if @item.completed_at do %>
          <i>completed at <%= @item.completed_at %></i>
        <% end %>
      </div>
    </section>
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2">
      FORM TODO
    </section>
    <%= for entry <- @item.entries do %>
      <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
        <div class="flex flex-row-reverse">
          <i>
            <%= format_date(entry.inserted_at) %>
          </i>
        </div>
        <%= markdown_to_html(entry.content) %>
      </section>
    <% end %>
    """
  end
end
