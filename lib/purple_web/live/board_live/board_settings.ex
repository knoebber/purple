defmodule PurpleWeb.BoardLive.BoardSettings do
  @moduledoc """
  Live view for managing user's boards.
  """

  alias Purple.Board
  alias Purple.Board.UserBoard
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  def apply_action(socket, :index, _) do
    assign(socket, :editable_board, nil)
  end

  def apply_action(socket, :edit, %{"id" => id}) do
    user_board_id = Purple.parse_int!(id)

    assign(
      socket,
      :editable_board,
      Enum.find(socket.assigns.user_boards, nil, fn ub ->
        ub.id == user_board_id
      end)
    )
  end

  def assign_data(socket) do
    assign(socket, :user_boards, Board.list_user_boards(socket.assigns.current_user.id))
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {
      :noreply,
      socket
      |> assign_data()
      |> apply_action(socket.assigns.live_action, params)
      |> assign(:page_title, "Board Settings")
    }
  end

  @impl Phoenix.LiveView
  def handle_event("new", _, socket) do
    {:ok, new_board} =
      Board.create_user_board(%UserBoard{
        name: "<New board>",
        user_id: socket.assigns.current_user.id
      })

    {:noreply, push_patch(socket, to: ~p"/board/settings/#{new_board}", replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.delete_user_board!(id)

    {
      :noreply,
      socket
      |> assign_data()
      |> assign_side_nav()
      |> put_flash(:info, "Deleted board")
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:saved_board, _id}, socket) do
    {
      :noreply,
      socket
      |> push_patch(to: ~p"/board/settings", replace: true)
      |> put_flash(:info, "Board saved")
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:tag_change, _}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Updated tags")
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <form phx-submit="new" class="sm:w-1/3">
      <.button class="mb-2">
        Add Board
      </.button>
    </form>
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <%= for user_board <- @user_boards do %>
        <.section class="mb-2">
          <div class="bg-purple-300 inline-links">
            <h2 class="ml-2 mb-2 inline"><%= user_board.name %></h2>
            <.link navigate={~p"/board/#{user_board.id}"}>View</.link>
            <span>|</span>
            <.link patch={~p"/board/settings/#{user_board}"}>
              <%= if(@editable_board && @editable_board.id == user_board.id,
                do: "Cancel",
                else: "Edit"
              ) %>
            </.link>
            <span>|</span>
            <.link
              href="#"
              phx-click="delete"
              phx-value-id={user_board.id}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </div>
          <%= if @editable_board && @editable_board.id == user_board.id do %>
            <div class="m-2 p-2 border border-purple-500 bg-purple-50 rounded">
              <.live_component
                module={PurpleWeb.BoardLive.UserBoardForm}
                id={user_board.id}
                user_board={user_board}
              />
            </div>
          <% else %>
            <div class="p-4">
              <div class="mb-2">
                Tags:
                <%= if length(user_board.tags) == 0 do %>
                  All
                <% else %>
                  <%= for tag <- user_board.tags do %>
                    <code class="inline">#<%= tag.name %></code>
                  <% end %>
                <% end %>
              </div>
              <div class="mb-2">
                Show done? <%= user_board.show_done %>
              </div>
            </div>
          <% end %>
        </.section>
      <% end %>
    </div>
    """
  end
end
