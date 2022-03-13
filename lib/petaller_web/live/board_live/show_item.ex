defmodule PetallerWeb.BoardLive.Show do
  use PetallerWeb, :live_view

  alias Petaller.Board
  alias Petaller.Board.ItemEntry
  alias PetallerWeb.BoardLive.Components

  defp page_title(item_id, :show_item), do: "Item #{item_id}"
  defp page_title(item_id, :edit_item), do: "Edit Item #{item_id}"

  defp save_entry(socket, entry, params) do
    case socket.assigns.live_action do
      :edit_item_entry ->
        Board.update_item_entry(entry, params)

      _ ->
        Board.create_item_entry(params)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :new_entry, %ItemEntry{})}
  end

  @impl true
  def handle_params(%{"id" => item_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(item_id, socket.assigns.live_action))
     |> assign(:item, Board.get_item!(item_id))
     |> assign(:entries, Board.get_item_entries(item_id))}
  end

  @impl true
  def handle_event("toggle_complete", %{"id" => item_id}, socket) do
    item = Board.get_item!(item_id)

    {:noreply,
     socket
     |> assign(:item, Board.set_item_complete!(item, !item.completed_at))}
  end

  @impl true
  def handle_info({:updated_item_entry, entry, params}, socket) do
    IO.puts("handle_info")
    IO.inspect(params)

    case save_entry(socket, entry, params) do
      {:ok, item} ->
        {:noreply,
         socket
         |> assign(:entries, Board.get_item_entries(item.item_id))
         |> put_flash(:info, "Entry saved")}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to save entry")}
    end
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
          <i>completed at <%= format_date(@item.completed_at) %></i>
        <% end %>
      </div>
    </section>
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <.live_component
        module={PetallerWeb.BoardLive.ItemEntryForm}
        id="create-item-entry"
        entry={@new_entry}
        item_id={@item.id}
      />
    </section>
    <%= for entry <- @entries do %>
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
