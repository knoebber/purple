defmodule PetallerWeb.BoardLive.ShowItem do
  use PetallerWeb, :live_view

  alias Petaller.Board
  alias Petaller.Board.ItemEntry

  defp page_title(item_id, :show_item), do: "Item #{item_id}"
  defp page_title(item_id, :edit_item), do: "Edit Item #{item_id}"
  defp page_title(_, :create_item_entry), do: "Create Item Entry"
  defp page_title(_, :edit_item_entry), do: "Edit Item Entry"

  defp assign_params(socket, item_id) do
    socket
    |> assign(:page_title, page_title(item_id, socket.assigns.live_action))
    |> assign(:item, Board.get_item!(item_id))
    |> assign(:entries, Board.get_item_entries(item_id))
  end

  defp get_entry(socket, entry_id) do
    Enum.find(socket.assigns.entries, %ItemEntry{}, fn entry ->
      Integer.to_string(entry.id) == entry_id
    end)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :new_entry_changeset, Board.change_item_entry(%ItemEntry{}))}
  end

  @impl true
  def handle_params(%{"id" => item_id, "entry_id" => entry_id}, _, socket) do
    socket = assign_params(socket, item_id)

    editable_entry = get_entry(socket, entry_id)

    entry_rows =
      editable_entry.content
      |> String.split("\n")
      |> length()

    {:noreply,
     socket
     |> assign(:editable_entry, editable_entry)
     |> assign(:entry_rows, entry_rows + 1)
     |> assign(:entry_update_changeset, Board.change_item_entry(editable_entry))}
  end

  @impl true
  def handle_params(%{"id" => item_id}, _, socket) do
    {:noreply, assign_params(socket, item_id)}
  end

  @impl true
  def handle_event("toggle_entry_collapse", %{"id" => id}, socket) do
    entry = get_entry(socket, id)
    Board.collapse_item_entries([id], !entry.is_collapsed)
    {:noreply, assign(socket, :entries, Board.get_item_entries(socket.assigns.item.id))}
  end

  @impl true
  def handle_event("delete_entry", %{"id" => id}, socket) do
    {entry_id, _} = Integer.parse(id)
    Board.delete_entry!(%ItemEntry{id: entry_id})

    {:noreply,
     socket
     |> put_flash(:info, "Entry deleted")
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
         |> put_flash(:info, "Entry created")
         |> push_redirect(
           to: Routes.board_show_item_path(socket, :show_item, socket.assigns.item.id)
         )}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to create entry")}
    end
  end

  @impl true
  def handle_event("save_sort_order", %{"list" => [_ | _] = entry_ids}, socket) do
    IO.inspect(entry_ids)

    Board.save_item_entry_sort_order(
      entry_ids
      |> Enum.with_index()
      |> Enum.map(fn {entry_id, i} ->
        Map.put(
          Enum.find(socket.assigns.entries, fn entry ->
            Integer.to_string(entry.id) == entry_id
          end),
          :sort_order,
          i
        )
      end)
    )

    {:noreply, socket}
  end

  defp entry_form(assigns) do
    ~H"""
    <.form for={@changeset} let={f} phx-submit={@action} class="p-4">
      <div class="flex flex-col mb-2">
        <%= hidden_input(f, :item_id, value: @item_id) %>
        <%= hidden_input(f, :is_collapsed, value: false) %>
        <%= label(f, :content) %>
        <%= textarea(f, :content, phx_hook: "AutoFocus", id: "entry-form", rows: @rows) %>
      </div>
      <%= submit("Save", phx_disable_with: "Saving...") %>
    </.form>
    """
  end

  defp entry_header(assigns) do
    ~H"""
    <div class="cursor-move flex justify-between bg-purple-300 p-1">
      <div class="inline-links">
        <%= if @editing do %>
          <strong>
            Edit Entry
          </strong>
          <span>|</span>
          <%= live_patch("Cancel",
            to: Routes.board_show_item_path(@socket, :show_item, @item.id)
          ) %>
        <% else %>
          <%= link(if(@entry.is_collapsed, do: "[+]", else: "[-]"),
            phx_click: "toggle_entry_collapse",
            phx_value_id: @entry.id,
            to: "#",
            class: "no-underline font-mono"
          ) %>
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
      <%= if @entry.is_collapsed do %>
        <strong class="whitespace-nowrap overflow-hidden text-ellipsis w-1/2 text-purple-900">
          <%= String.slice(strip_markdown(@entry.content), 0, 100) %>
        </strong>
      <% end %>
      <i>
        <%= format_date(@entry.updated_at) %>
      </i>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center">
      <h1>
        <%= "Item #{@item.id}: " %>
        <%= live_patch(@item.description, to: Routes.board_show_item_path(@socket, :edit_item, @item)) %>
      </h1>
      <%= live_patch to: Routes.board_show_item_path(@socket, :create_item_entry, @item) do %>
        <button disabled={@live_action == :create_item_entry} class="btn p-1 ml-2">
          Create Entry
        </button>
      <% end %>
    </div>
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
    <%= if @live_action == :create_item_entry do %>
      <section class="lg:w-1/2 md:w-full window mt-2 mb-2">
        <div class="flex justify-between bg-purple-300 p-1">
          <div class="inline-links">
            <strong>New Entry</strong>
            <span>|</span>
            <%= live_patch("Cancel",
              to: Routes.board_show_item_path(@socket, :show_item, @item.id)
            ) %>
          </div>
        </div>
        <.entry_form
          rows={5}
          action="create_entry"
          changeset={@new_entry_changeset}
          item_id={@item.id}
        />
      </section>
    <% end %>

    <div id="entry-container" phx-hook="Sortable">
      <%= for entry <- @entries do %>
        <section
          class="lg:w-1/2 md:w-full window mt-2 mb-2 js-sortable-item"
          id={Integer.to_string(entry.id)}
        >
          <%= if @live_action == :edit_item_entry and @editable_entry.id == entry.id do %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={true} />
            <.entry_form
              rows={@entry_rows}
              action="update_entry"
              changeset={@entry_update_changeset}
              item_id={@item.id}
            />
          <% else %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={false} />
            <%= unless entry.is_collapsed do %>
              <div class="markdown-content">
                <%= markdown_to_html(entry.content) %>
              </div>
            <% end %>
          <% end %>
        </section>
      <% end %>
    </div>
    """
  end
end
