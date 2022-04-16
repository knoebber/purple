defmodule PetallerWeb.BoardLive.ShowItemFile do
  use PetallerWeb, :live_view

  alias Petaller.Uploads
  alias Petaller.Uploads.FileRef

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref!(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:item_id, item_id)
      |> assign(:page_title, Uploads.file_title(file_ref))
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Uploads.delete_file_upload!(socket.assigns.file_ref.id)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted file")
      |> push_redirect(
        to: Routes.board_show_item_path(socket, :show_item, socket.assigns.item_id)
      )
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <%= live_patch(
        "Board",
        to: Routes.board_index_path(@socket, :index)
      ) %> /
      <%= live_patch("Item #{@item_id}",
        to: Routes.board_show_item_path(@socket, :show_item, @item_id)
      ) %> / <%= @page_title %>
    </h1>

    <div class="flex bg-purple-300 inline-links p-1 border rounded border-purple-500">
      <%= link("Download", to: Routes.file_path(@socket, :download, @file_ref)) %>
      <%= link("Delete", to: "#", phx_click: "delete") %>
    </div>
    <%= if Uploads.image?(@file_ref) do %>
      <img
        class="inline border border-purple-500 m-1"
        width={@file_ref.image_width}
        height={@file_ref.image_height}
        src={Routes.file_path(@socket, :show, @file_ref)}
      />
    <% end %>
    """
  end
end
