defmodule PetallerWeb.BoardLive.ItemGallery do
  use PetallerWeb, :live_view

  alias Petaller.Uploads
  alias Petaller.Uploads.FileRef

  defp page_title(file_ref = %FileRef{}), do: Path.basename(file_ref.path <> file_ref.extension)

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref!(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:item_id, item_id)
      |> assign(:page_title, page_title(file_ref))
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      Board /
      <%= live_patch("Item #{@item_id}",
        to: Routes.board_show_item_path(@socket, :show_item, @item_id)
      ) %> /
      <%= link(@page_title, to: Routes.file_path(@socket, :download, @file_ref)) %>
    </h1>
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
