defmodule PurpleWeb.BoardLive.ShowItemFile do
  use PurpleWeb, :live_view
  alias Purple.Uploads

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref!(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:item_id, item_id)
      |> assign(:page_title, Uploads.file_title(file_ref))
      |> PurpleWeb.BoardLive.Helpers.assign_side_nav()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Uploads.delete_file_upload!(socket.assigns.file_ref.id)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted file")
      |> push_redirect(to: ~p"/board/item/#{socket.assigns.item_id}", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link navigate={~p"/board"}>Board</.link>
       / <.link navigate={~p"/board/item/#{@item_id}"}>Item <%= @item_id %></.link>
       / <%= @page_title %>
    </h1>

    <div class="flex bg-purple-300 inline-links p-1 border rounded border-purple-500">
      <.link href={~p"/files/#{@file_ref}/download"}>Download</.link>
      <.link href="#" phx-click="delete" data-confirm="Are you sure?">Delete</.link>
    </div>
    <%= if Uploads.image?(@file_ref) do %>
      <img
        class="inline border border-purple-500 m-1"
        width={@file_ref.image_width}
        height={@file_ref.image_height}
        src={~p"/files/#{@file_ref}"}
      />
    <% end %>
    """
  end
end
