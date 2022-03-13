defmodule PetallerWeb.BoardLive.ShowItem do
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
  def handle_event("toggle_complete", _, socket) do
    item = socket.assigns.item

    {:noreply,
     socket
     |> assign(:item, Board.set_item_complete!(item, !item.completed_at))}
  end

  @impl true
  def handle_event("delete_self", _, socket) do
    Board.delete_item!(socket.assigns.item)

    {:noreply,
     socket
     |> put_flash(:info, "Item deleted")
     |> push_redirect(to: Routes.board_index_path(socket, :index))}
  end

  @impl true
  def handle_event("delete_entry", %{"id" => id}, socket) do
    {entry_id, _} = Integer.parse(id)
    Board.delete_entry!(%ItemEntry{id: entry_id})

    {:noreply,
     socket
     |> put_flash(:info, "Item deleted")
     |> assign(:entries, Board.get_item_entries(socket.assigns.item.id))}
  end

  @impl true
  def handle_info({:updated_item_entry, entry, params}, socket) do
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
    <h1><%= "Item #{@item.id}: #{@item.description}" %></h1>
    <%= if @live_action == :edit_item do %>
      <.modal return_to={Routes.board_show_item_path(@socket, :show_item, @item)}>
        <.live_component
          module={PetallerWeb.BoardLive.ItemForm}
          id={@item.id}
          title={@page_title}
          action={@live_action}
          item={@item}
          return_to={Routes.board_show_item_path(@socket, :show_item, @item)}
        />
      </.modal>
    <% end %>
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <div class="flex justify-between">
        <div class="inline-links">
          <span>
            Complete:
            <Components.toggle_complete item={@item} />
          </span>
          <span>|</span>
          <%= live_patch("Edit", to: Routes.board_show_item_path(@socket, :edit_item, @item)) %>
          <span>|</span>
          <%= link("Delete",
            phx_click: "delete_self",
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        </div>
        <i>
          created at <%= format_date(@item.inserted_at) %>
        </i>
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
      <section class="lg:w-1/2 md:w-full window mt-2 mb-2">
        <div class="flex justify-between bg-purple-300 p-1">
          <div class="inline-links">
            <%= live_patch("Edit", to: Routes.board_show_item_path(@socket, :edit_item, @item)) %>
            <span>|</span>
            <%= link("Delete",
              phx_click: "delete_entry",
              phx_value_id: entry.id,
              data: [confirm: "Are you sure?"],
              to: "#"
            ) %>
          </div>
          <i>
            <%= format_date(entry.inserted_at) %>
          </i>
        </div>
        <div class="p-4">
          <%= markdown_to_html(entry.content) %>
        </div>
      </section>
    <% end %>
    """
  end
end
