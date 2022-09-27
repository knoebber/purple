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
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>
      Board /
      <.link redirect={Routes.board_show_item_path(@socket, :show, @item_id)}>
        Item <%= @item_id %>
      </.link>
      / Gallery
    </h1>
    <%= for ref <- @image_refs do %>
      <.link
        redirect={Routes.board_show_item_file_path(@socket, :show, @item_id, ref.id)}
        class="no-underline"
      >
        <img
          class="border border-purple-500 mb-2 mt-2"
          height={ref.image_height}
          loading="lazy"
          src={Routes.file_path(@socket, :show, ref)}
          width={ref.image_width}
        />
      </.link>
    <% end %>
    """
  end
end
