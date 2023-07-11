defmodule PurpleWeb.BoardLive.Board do
  @moduledoc """
  Live view for viewing items in a board
  """

  alias Purple.Board
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🧱"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"user_board_id" => board_id}) do
    user_board = Board.get_user_board(board_id)

    case user_board do
      nil -> nil
      _ -> user_board.name
    end
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    user_board = Board.get_user_board!(Purple.int_from_map!(params, "user_board_id"))

    saved_tag_names =
      user_board.tags
      |> Purple.maybe_list()
      |> Enum.map(& &1.name)

    {
      :noreply,
      socket
      |> assign(:page_title, user_board.name)
      |> assign(:user_board, user_board)
      |> assign(:items, Board.list_items(%{tag: saved_tag_names}))
    }
  end

  defp col_class(status) do
    case status do
      :TODO -> "col-start-1"
      :DONE -> "col-start-2"
      :INFO -> "col-start-3"
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="mb-2 flex gap-4">
      <.link navigate={item_create_path(@user_board.id)}>
        <.button type="button">Add Item</.button>
      </.link>
      <h1 class="mb-2"><%= @page_title %></h1>
    </div>
    <div class="grid grid-cols-3 gap-4">
      <div class={col_class(:TODO)}>
        <h2 class="text-center">TODO</h2>
      </div>
      <div class={col_class(:DONE)}>
        <h2 class="text-center">DONE</h2>
      </div>
      <div class={col_class(:INFO)}>
        <h2 class="text-center">INFO</h2>
      </div>
      <%= for item <- @items do %>
        <.section class="mb-2">
          <div class={["bg-purple-300", col_class(item.status)]}>
            <h2 class="ml-2 mb-2 inline">
              <.link navigate={~p"/board/item/#{item.id}"}>
                <%= item.description %>
              </.link>
            </h2>
          </div>
        </.section>
      <% end %>
    </div>
    """
  end
end
