defmodule PurpleWeb.BoardLive.ShowItemFile do
  alias Purple.Uploads
  use PurpleWeb, :live_view

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id, "file_id" => file_id}, _url, socket) do
    file_ref = Uploads.get_file_ref(file_id)

    {
      :noreply,
      socket
      |> assign(:file_ref, file_ref)
      |> assign(:page_title, if(file_ref, do: file_ref.title, else: "not found"))
      |> assign(:item, Purple.Board.get_item!(item_id))
      |> PurpleWeb.BoardLive.Helpers.assign_side_nav()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Uploads.delete_model_reference!(socket.assigns.file_ref, socket.assigns.item)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted file")
      |> push_navigate(to: ~p"/board/item/#{socket.assigns.item}", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def handle_info(:updated_file_ref, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "File reference updated")
      |> push_patch(
        to: ~p"/board/item/#{socket.assigns.item}/files/#{socket.assigns.file_ref.id}",
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      <.link navigate={~p"/board"}>Board</.link>
      / <.link navigate={~p"/board/item/#{@item}"}>{@item.description}</.link>
      / {@page_title}
    </h1>
    <%= if @file_ref do %>
      <.file_ref_header
        file_ref={@file_ref}
        edit_url={~p"/board/item/#{@item}/files/#{@file_ref}/edit"}
      />
      <.modal
        :if={@live_action == :edit}
        id="edit-file-ref-modal"
        on_cancel={JS.patch(~p"/board/item/#{@item}/files/#{@file_ref}", replace: true)}
        show
      >
        <:title>Update File Reference</:title>
        <.live_component module={PurpleWeb.UpdateFileRef} id={@file_ref.id} file_ref={@file_ref} />
      </.modal>
      <.render_file_ref file_ref={@file_ref} />
    <% else %>
      <span>⚠️ File reference not found </span>
    <% end %>
    """
  end
end
