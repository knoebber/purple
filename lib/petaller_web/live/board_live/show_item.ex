defmodule PetallerWeb.BoardLive.ShowItem do
  use PetallerWeb, :live_view

  alias Petaller.Board
  alias Petaller.Board.ItemEntry
  alias PetallerWeb.BoardLive.Components

  defp page_title(item_id, :show_item), do: "Item #{item_id}"
  defp page_title(item_id, :edit_item), do: "Edit Item #{item_id}"
  defp page_title(_, :edit_item_entry), do: "Edit Item Entry"

  defp assign_params(socket, item_id) do
    socket
    |> assign(:page_title, page_title(item_id, socket.assigns.live_action))
    |> assign(:item, Board.get_item!(item_id))
    |> assign(:entries, Board.get_item_entries(item_id))
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :new_entry_changeset, Board.change_item_entry(%ItemEntry{}))}
  end

  @impl true
  def handle_params(%{"id" => item_id, "entry_id" => entry_id}, _, socket) do
    socket = assign_params(socket, item_id)

    editable_entry =
      Enum.find(socket.assigns.entries, %ItemEntry{}, fn e ->
        Integer.to_string(e.id) == entry_id
      end)

    {:noreply,
     socket
     |> assign(:editable_entry, editable_entry)
     |> assign(:entry_update_changeset, Board.change_item_entry(editable_entry))}
  end

  @impl true
  def handle_params(%{"id" => item_id}, _, socket) do
    {:noreply, assign_params(socket, item_id)}
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
  def handle_event("update_entry", %{"item_entry" => params}, socket) do
    case Board.update_item_entry(socket.assigns.editable_entry, params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry saved")
         |> push_redirect(to: Routes.board_show_item_path(socket, :show_item, entry.item_id))}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to save entry")}
    end
  end

  @impl true
  def handle_event("create_entry", %{"item_entry" => params}, socket) do
    case Board.create_item_entry(params) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> assign(:entries, Board.get_item_entries(entry.item_id))
         |> put_flash(:info, "Entry created")}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to create entry")}
    end
  end

  defp entry_form(assigns) do
    ~H"""
    <.form for={@changeset} let={f} phx-submit={@action} class="p-4">
      <div class="flex flex-col mb-2">
        <%= hidden_input(f, :item_id, value: @item_id) %>
        <%= label(f, :content) %>
        <%= textarea(f, :content) %>
      </div>
      <%= submit("Save", phx_disable_with: "Saving...") %>
    </.form>
    """
  end

  defp item_controls(assigns) do
    ~H"""
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
        <%= format_date(@item.updated_at) %>
      </i>
    </div>
    <div>
      <%= if @item.completed_at do %>
        <i>completed at <%= format_date(@item.completed_at) %></i>
      <% end %>
    </div>
    """
  end

  defp entry_header(assigns) do
    ~H"""
    <div class="flex justify-between bg-purple-300 p-1">
      <div class="inline-links">
        <%= if @editing do %>
          <%= live_patch("Cancel",
            to: Routes.board_show_item_path(@socket, :show_item, @item.id)
          ) %>
        <% else %>
          <%= live_patch("Edit",
            to: Routes.board_show_item_path(@socket, :edit_item_entry, @item.id, @entry.id)
          ) %>
          <span>|</span>
          <%= link("Delete",
            phx_click: "delete_entry",
            phx_value_id: @entry.id,
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        <% end %>
      </div>
      <i>
        <%= format_date(@entry.updated_at) %>
      </i>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1><%= "Item #{@item.id}: #{@item.description}" %></h1>
    <%= if @live_action == :edit_item do %>
      <.modal return_to={Routes.board_show_item_path(@socket, :show_item, @item)} title={@page_title}>
        <.live_component
          module={PetallerWeb.BoardLive.ItemForm}
          id={@item.id}
          action={@live_action}
          item={@item}
          return_to={Routes.board_show_item_path(@socket, :show_item, @item)}
        />
      </.modal>
    <% end %>
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <.item_controls socket={@socket} item={@item} />
    </section>
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2">
      <.entry_form action="create_entry" changeset={@new_entry_changeset} item_id={@item.id} />
    </section>
    <%= for entry <- @entries do %>
      <section class="lg:w-1/2 md:w-full window mt-2 mb-2">
        <%= if @live_action == :edit_item_entry and @editable_entry.id == entry.id do %>
          <.entry_header socket={@socket} item={@item} entry={entry} editing={true} />
          <.entry_form action="update_entry" changeset={@entry_update_changeset} item_id={@item.id} />
        <% else %>
          <.entry_header socket={@socket} item={@item} entry={entry} editing={false} />
          <div class="p-4">
            <%= markdown_to_html(entry.content) %>
          </div>
        <% end %>
      </section>
    <% end %>
    """
  end
end
