defmodule PurpleWeb.BoardLive.ItemGallery do
  use PurpleWeb, :live_view

  alias Purple.Uploads

  @impl Phoenix.LiveView
  def handle_params(%{"id" => item_id}, _url, socket) do
    {
      :noreply,
      socket
      |> assign(:item_id, item_id)
      |> assign(:image_refs, Uploads.get_images_by_item(item_id))
      |> assign(:page_title, "Item #{item_id} gallery")
      |> PurpleWeb.BoardLive.Helpers.assign_side_nav()
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      Board /
      <.link navigate={~p"/board/item/#{@item_id}"}>
        Item <%= @item_id %>
      </.link>
      / Gallery
    </h1>
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-1">
      <.link
        :for={ref <- @image_refs}
        navigate={~p"/board/item/#{@item_id}/files/#{ref}"}
        class="no-underline"
      >
        <img
          class="border border-purple-500 mb-2 mt-2"
          height={ref.image_height}
          loading="lazy"
          src={~p"/files/#{ref}"}
          width={ref.image_width}
        />
      </.link>
    </div>
    """
  end
end
