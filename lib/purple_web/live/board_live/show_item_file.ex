defmodule PurpleWeb.BoardLive.ShowItemFile do
  alias Purple.Uploads
  alias Purple.Uploads.FileRef
  use PurpleWeb, :live_view

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref!(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:item_id, item_id)
      |> assign(:page_title, FileRef.title(file_ref))
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
  def handle_info(:updated_file_ref, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "File reference updated")
      |> push_patch(
        to: ~p"/board/item/#{socket.assigns.item_id}/files/#{socket.assigns.file_ref.id}",
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link navigate={~p"/board"}>Board</.link>
      /
      <.link navigate={~p"/board/item/#{@item_id}"}>Item <%= @item_id %></.link>
      / <%= @page_title %>
    </h1>
    <div class="flex justify-between bg-purple-300 p-1 border rounded border-purple-500">
      <div class="inline-links">
        <.link
          target="_blank"
          href={~p"/files/#{@file_ref}/open/#{@file_ref.file_name}" <> @file_ref.extension}
        >
          Open
        </.link>
        <span>|</span>
        <.link href={~p"/files/#{@file_ref}/download"}>Download</.link>
        <span>|</span>
        <.link patch={~p"/board/item/#{@item_id}/files/#{@file_ref}/edit"}>Edit</.link>
        <span>|</span>
        <.link href="#" phx-click="delete" data-confirm="Are you sure?">Delete</.link>
        <span>|</span>
        <strong><%= FileRef.size_string(@file_ref) %></strong>
      </div>
      <.timestamp model={@file_ref} />
    </div>
    <.modal
      :if={@live_action == :edit}
      id="edit-file-ref-modal"
      on_cancel={JS.patch(~p"/board/item/#{@item_id}/files/#{@file_ref}", replace: true)}
      show
    >
      <:title>Update File Reference</:title>
      <.live_component module={PurpleWeb.UpdateFileRef} id={@file_ref.id} file_ref={@file_ref} />
    </.modal>
    <img
      :if={Uploads.image?(@file_ref)}
      class="inline border border-purple-500 m-1"
      width={@file_ref.image_width}
      height={@file_ref.image_height}
      src={~p"/files/#{@file_ref}"}
    />
    <div :if={Uploads.pdf?(@file_ref)} class="flex justify-between w-full mt-2">
      <.button class="js-prev" type="button">Prev</.button>
      <input class="js-zoom" type="range" value="1.5" min="0" max="2" step=".1" />
      <.button class="js-next" type="button">Next</.button>
    </div>
    <canvas
      :if={Uploads.pdf?(@file_ref)}
      class="mt-1"
      phx-hook="PDF"
      id="pdf-canvas"
      data-path={~p"/files/#{@file_ref}"}
    >
    </canvas>
    """
  end
end
