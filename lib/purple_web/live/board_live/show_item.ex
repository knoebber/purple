defmodule PurpleWeb.BoardLive.ShowItem do
  alias Purple.Board
  alias Purple.Board.ItemEntry
  alias Purple.Uploads
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  defp assign_uploads(socket, item_id) do
    files = Uploads.get_files_by_item(item_id)

    socket
    |> assign(:file_refs, Enum.reject(files, fn f -> Uploads.image?(f) end))
    |> assign(:image_refs, Enum.filter(files, fn f -> Uploads.image?(f) end))
    |> assign(:num_total_files, length(files))
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
    assign(socket, :editable_entry, editable_entry = get_entry(socket, entry_id))
  end

  defp apply_action(socket, _, %{"id" => item_id}) do
    assign_default_params(socket, item_id)
  end

  defp get_entry(socket, entry_id) do
    Enum.find(socket.assigns.entries, %ItemEntry{}, fn entry ->
      Integer.to_string(entry.id) == entry_id
    end)
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
    "🌻"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => item_id}) do
    if Purple.parse_int(item_id, nil) do
      item = Board.get_item(item_id)

      case item do
        nil -> nil
        %{status: :INFO} -> item.description
        _ -> item.description <> " (#{item.status})"
      end
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("create_entry", _, socket) do
    item_id = socket.assigns.item.id
    {:ok, new_entry} = Board.create_item_entry(%{content: "# New Entry"}, item_id)

    {:noreply,
     push_patch(socket, to: ~p"/board/item/#{item_id}/entry/#{new_entry.id}", replace: true)}
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
    case Board.update_item_entry(socket.assigns.editable_entry, params) do
      {:ok, entry} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Entry saved")
          |> push_patch(to: ~p"/board/item/#{entry.item_id}", replace: true)
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
  def handle_event("validate_entry", _, socket) do
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
      |> push_redirect(to: ~p"/board", replace: true)
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
    <.link patch={~p"/board/item/#{@item}"} replace={true}>Cancel</.link>
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
          <.link patch={~p"/board/item/#{@item}/entry/#{@entry}"} replace={true}>
            Edit
          </.link>
          <span>|</span>
          <.link
            href="#"
            phx-click="delete_entry"
            phx-value-id={@entry.id}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
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
      <.link navigate={~p"/board"}>
        Board
      </.link>
      / <%= "Item #{@item.id}" %>
    </h1>
    <.section class="mt-2 mb-2">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <%= if @live_action == :edit_item do %>
            <strong>Edit</strong>
            <span>|</span>
            <.cancel_link item={@item} socket={@socket} />
          <% else %>
            <strong><%= @item.status %></strong>
            <span>|</span>
            <.link patch={~p"/board/item/#{@item}/edit"} replace={true}>
              Edit
            </.link>
          <% end %>
          <span>|</span>
          <a href="#" phx-click="delete" phx-value-id={@item.id} data-confirm="Are you sure?">
            Delete
          </a>
          <span>|</span>
          <.link href="#" phx-click="create_entry">
            Create Entry
          </.link>
        </div>
        <.timestamp model={@item} />
      </div>
      <%= if @live_action == :edit_item do %>
        <div class="m-2 p-2 border border-purplength(@image_refs) + length(@file_refs)le-500 bg-purple-50 rounded">
          <.live_component
            module={PurpleWeb.BoardLive.UpdateItem}
            id={@item.id}
            action={@live_action}
            item={@item}
            return_to={~p"/board/item/#{@item}"}
          />
        </div>
      <% else %>
        <.markdown content={"# #{@item.description}"} link_type={:board} />
      <% end %>
      <div>
        <span>
          <.link href="#" phx-click="toggle_files_collapsed" class="ml-1 no-underline font-mono">
            <%= if(!@item.show_files, do: "[+]", else: "[-]") %>
          </.link>
          <%= if @num_total_files > 0 do %>
            <.link navigate={~p"/board/item/#{@item}/files"}>
              File Uploads
            </.link>
          <% else %>
            File Uploads
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
            return_to={~p"/board/item/#{@item}"}
          />
        </div>
        <%= if length(@image_refs) + length(@file_refs) > 0 do %>
          <%= for ref <- @image_refs do %>
            <div class="inline">
              <div class="inline-flex flex-col">
                <div
                  id={"copy-markdown-#{ref.id}"}
                  phx-hook="CopyMarkdownImage"
                  name={Uploads.FileRef.title(ref)}
                  value={~p"/files/#{ref}"}
                  class="cursor-pointer w-1/6"
                >
                  🔗
                </div>
                <.link class="no-underline" navigate={~p"/board/item/#{@item}/files/#{ref}"}>
                  <img
                    id={"thumbnail-#{ref.id}"}
                    class="inline border border-purple-500 m-1"
                    width="150"
                    height="150"
                    src={~p"/files/#{ref}/thumbnail"}
                  />
                </.link>
              </div>
            </div>
          <% end %>
          <div :if={length(@file_refs) > 0} class="p-3">
            <strong>Files</strong>
            <ul class="ml-8">
              <li :for={ref <- @file_refs}>
                <.link navigate={~p"/board/item/#{@item}/files/#{ref}"}>
                  <%= Uploads.FileRef.title(ref) %>
                </.link>
              </li>
            </ul>
          </div>
        <% end %>
      <% end %>
    </.section>
    <div id="entry-container" phx-hook="Sortable">
      <%= for entry <- @entries do %>
        <.section class="mt-2 mb-2 js-sortable-item" id={Integer.to_string(entry.id)}>
          <%= if @live_action == :edit_entry and @editable_entry.id == entry.id do %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={true} />
            <.live_component
              module={PurpleWeb.BoardLive.EntryForm}
              id={@editable_entry.id}
              entry={@editable_entry}
              item_id={@item.id}
              return_to={~p"/board/item/#{@item}"}
              num_rows={get_num_textarea_rows(@editable_entry.content)}
            />
          <% else %>
            <.entry_header socket={@socket} item={@item} entry={entry} editing={false} />
            <%= unless entry.is_collapsed do %>
              <.markdown
                checkbox_map={make_checkbox_map(entry)}
                content={entry.content}
                fancy_link_map={@fancy_link_map}
                link_type={:board}
              />
            <% end %>
          <% end %>
        </.section>
      <% end %>
    </div>
    """
  end
end
