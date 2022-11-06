defmodule PurpleWeb.BoardLive.ShowItem do
  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.ItemEntry
  alias Purple.Uploads

  @behaviour PurpleWeb.FancyLink

  defp assign_uploads(socket, item_id) do
    files = Uploads.get_files_by_item(item_id)

    socket
    |> assign(:file_refs, Enum.reject(files, fn f -> Uploads.image?(f) end))
    |> assign(:image_refs, Enum.filter(files, fn f -> Uploads.image?(f) end))
    |> assign(:total_files, length(files))
  end

  defp assign_entries(socket) do
    entries = Board.list_item_entries(socket.assigns.item.id, :checkboxes)

    fancy_link_map =
      entries
      |> Enum.reduce([], fn entry, route_info ->
        PurpleWeb.FancyLink.extract_routes_from_markdown(entry.content) ++ route_info
      end)
      |> PurpleWeb.FancyLink.build_fancy_link_map()

    socket
    |> assign(:entries, entries)
    |> assign(:fancy_link_map, fancy_link_map)
  end

  defp assign_default_params(socket, item_id) do
    item = Board.get_item!(item_id)

    socket
    |> assign_uploads(item_id)
    |> assign(:page_title, item.description)
    |> assign(:item, item)
    |> assign_entries()
  end

  defp apply_action(socket, :edit_entry, %{"id" => item_id, "entry_id" => entry_id}) do
    socket = assign_default_params(socket, item_id)

    editable_entry = get_entry(socket, entry_id)

    socket
    |> assign(:editable_entry, editable_entry)
    |> assign(:entry_update_changeset, Board.change_item_entry(editable_entry))
  end

  defp apply_action(socket, :create_entry, %{"id" => item_id}) do
    socket
    |> assign_default_params(item_id)
    |> assign(:new_entry_changeset, Board.change_item_entry(%ItemEntry{}))
  end

  defp apply_action(socket, _, %{"id" => item_id}) do
    assign_default_params(socket, item_id)
  end

  defp get_entry(socket, entry_id) do
    Enum.find(socket.assigns.entries, %ItemEntry{}, fn entry ->
      Integer.to_string(entry.id) == entry_id
    end)
  end

  defp save_entry(socket, :create_entry, params) do
    Board.create_item_entry(params, socket.assigns.item.id)
  end

  defp save_entry(socket, :edit_entry, params) do
    Board.update_item_entry(socket.assigns.editable_entry, params)
  end

  defp make_checkbox_map(entry) do
    Enum.reduce(
      entry.checkboxes,
      %{},
      fn checkbox, acc -> Map.put(acc, checkbox.description, checkbox) end
    )
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "Item"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => item_id}) do
    item = Board.get_item(item_id)

    if item do
      item.description
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle-checkbox", %{"id" => id}, socket) do
    checkbox = Board.get_entry_checkbox!(id)
    Board.set_checkbox_done(checkbox, !checkbox.is_done)
    {:noreply, assign_entries(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_entry_collapse", %{"id" => id}, socket) do
    entry = get_entry(socket, id)
    Board.collapse_item_entries([id], !entry.is_collapsed)
    {:noreply, assign_entries(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_files_collapsed", _, socket) do
    item = socket.assigns.item
    Board.toggle_show_item_files!(item, !item.show_files)

    {
      :noreply,
      assign(socket, :item, Board.get_item!(item.id))
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete_entry", %{"id" => id}, socket) do
    {entry_id, _} = Integer.parse(id)
    Board.delete_entry!(%ItemEntry{id: entry_id, item_id: socket.assigns.item.id})

    {
      :noreply,
      socket
      |> put_flash(:info, "Entry deleted")
      |> assign_entries()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("save_entry", %{"item_entry" => params}, socket) do
    case save_entry(socket, socket.assigns.live_action, params) do
      {:ok, entry} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Entry saved")
          |> push_patch(to: Routes.board_show_item_path(socket, :show, entry.item_id), replace: true)
        }

      {:error, changeset} ->
        socket =
          if socket.assigns.live_action == :create_entry do
            assign(socket, :new_entry_changeset, changeset)
          else
            assign(socket, :entry_update_changeset, changeset)
          end

        {:noreply, put_flash(socket, :error, "Failed to create entry")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("save_sort_order", %{"list" => [_ | _] = entry_ids}, socket) do
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

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.get_item!(id)
    |> Board.delete_item!()

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted item")
      |> push_redirect(to: Routes.board_index_path(socket, :index))
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:upload_result, result}, socket) do
    Enum.each(result.uploaded_files, fn file_ref ->
      Uploads.add_file_to_item!(file_ref, socket.assigns.item)
    end)

    {
      :noreply,
      socket
      |> assign_uploads(socket.assigns.item.id)
      |> put_flash(:info, "Uploaded #{result.num_uploaded}/#{result.num_attempted} files")
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  defp cancel_link(assigns) do
    ~H"""
    <.link patch={Routes.board_show_item_path(@socket, :show, @item.id)} replace={true}>Cancel</.link>
    """
  end

  defp entry_form(assigns) do
    ~H"""
    <.form :let={f} for={@changeset} phx-submit={@action} class="p-4">
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
            Edit
          </strong>
          <span>|</span>
          <.cancel_link item={@item} socket={@socket} />
        <% else %>
          <a
            href="#"
            phx-click="toggle_entry_collapse"
            phx-value-id={@entry.id}
            class="no-underline font-mono"
          >
            <%= if(@entry.is_collapsed, do: "[+]", else: "[-]") %>
          </a>
          <.link
            patch={Routes.board_show_item_path(@socket, :edit_entry, @item.id, @entry.id)}
            replace={true}
          >
            Edit
          </.link>
          <span>|</span>
          <a href="#" phx-click="delete_entry" phx-value-id={@entry.id} data-confirm="Are you sure?">
            Delete
          </a>
        <% end %>
      </div>
      <%= if @entry.is_collapsed do %>
        <strong class="whitespace-nowrap overflow-hidden text-ellipsis w-1/2 text-purple-900">
          <%= String.slice(strip_markdown(@entry.content), 0, 100) %>
        </strong>
      <% end %>
      <.timestamp model={@entry} />
    </div>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link patch={index_path()}>
        Board
      </.link>
      / <%= "Item #{@item.id}" %>
    </h1>
    <section class="mt-2 mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <%= if @live_action == :edit_item do %>
            <strong>Edit</strong>
            <span>|</span>
            <.cancel_link item={@item} socket={@socket} />
          <% else %>
            <strong><%= @item.status %></strong>
            <span>|</span>
            <.link patch={Routes.board_show_item_path(@socket, :edit_item, @item)} replace={true}>
              Edit
            </.link>
          <% end %>
          <span>|</span>
          <a href="#" phx-click="delete" phx-value-id={@item.id} data-confirm="Are you sure?">
            Delete
          </a>
          <span>|</span>
          <.link patch={Routes.board_show_item_path(@socket, :create_entry, @item)} replace={true}>
            Create Entry
          </.link>
        </div>
        <.timestamp model={@item} />
      </div>
      <%= if @live_action == :edit_item do %>
        <div class="m-2 p-2 border border-purple-500 bg-purple-50 rounded">
          <.live_component
            module={PurpleWeb.BoardLive.UpdateItem}
            id={@item.id}
            action={@live_action}
            item={@item}
            return_to={Routes.board_show_item_path(@socket, :show, @item)}
          />
        </div>
      <% else %>
        <div class="markdown-content">
          <%= markdown("# #{@item.description}", link_type: :board) %>
        </div>
      <% end %>
      <div>
        <span>
          <.link href="#" phx-click="toggle_files_collapsed" class="ml-1 no-underline font-mono">
            <%= if(!@item.show_files, do: "[+]", else: "[-]") %>
          </.link>
          <%= if @total_files > 0 do %>
            <.link navigate={Routes.board_item_gallery_path(@socket, :index, @item)}>
              <%= @total_files %> file<%= if length(@image_refs) != 1, do: "s" %>
            </.link>
          <% else %>
            No files
          <% end %>
        </span>
      </div>
      <%= if @item.show_files do %>
        <div class="m-2 p-2">
          <.live_component
            accept={:any}
            dir={"item/#{@item.id}"}
            id={"item-#{@item.id}-upload"}
            max_entries={20}
            module={PurpleWeb.LiveUpload}
            return_to={Routes.board_show_item_path(@socket, :show, @item.id)}
          />
        </div>
        <%= if length(@image_refs) + length(@file_refs) > 0 do %>
          <%= for ref <- @image_refs do %>
            <div class="inline">
              <div class="inline-flex flex-col">
                <div
                  id={"copy-markdown-#{ref.id}"}
                  phx-hook="CopyMarkdownImage"
                  name={Uploads.file_title(ref)}
                  value={Routes.file_path(@socket, :show, ref)}
                  class="cursor-pointer w-1/6"
                >
                  🔗
                </div>
                <.link
                  class="no-underline"
                  navigate={Routes.board_show_item_file_path(@socket, :show, @item.id, ref.id)}
                >
                  <img
                    id={"thumbnail-#{ref.id}"}
                    class="inline border border-purple-500 m-1"
                    width="150"
                    height="150"
                    src={Routes.file_path(@socket, :show_thumbnail, ref)}
                  />
                </.link>
              </div>
            </div>
          <% end %>
          <ul class="ml-8">
            <%= for ref <- @file_refs do %>
              <li>
                <.link navigate={Routes.board_show_item_file_path(@socket, :show, @item.id, ref.id)}>
                  <%= Uploads.file_title(ref) %>
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      <% end %>
    </section>
    <section :if={@live_action == :create_entry} class="window mt-2 mb-2">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <strong>New Entry</strong>
          <span>|</span>
          <.cancel_link item={@item} socket={@socket} />
        </div>
      </div>
      <.entry_form rows={5} action="save_entry" changeset={@new_entry_changeset} item_id={@item.id} />
    </section>
    <div id="entry-container" phx-hook="Sortable">
      <%= for entry <- @entries do %>
        <section class="window mt-2 mb-2 js-sortable-item" id={Integer.to_string(entry.id)}>
          <%= if @live_action == :edit_entry and @editable_entry.id == entry.id do %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={true} />
            <.entry_form
              rows={get_num_textarea_rows(entry.content)}
              action="save_entry"
              changeset={@entry_update_changeset}
              item_id={@item.id}
            />
          <% else %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={false} />
            <%= unless entry.is_collapsed do %>
              <div class="markdown-content">
                <%= markdown(entry.content,
                  link_type: :board,
                  checkbox_map: make_checkbox_map(entry),
                  fancy_link_map: @fancy_link_map
                ) %>
              </div>
            <% end %>
          <% end %>
        </section>
      <% end %>
    </div>
    """
  end
end
