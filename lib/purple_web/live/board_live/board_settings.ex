defmodule PurpleWeb.BoardLive.BoardSettings do
  @moduledoc """
  Live view for managing user's boards.
  """

  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.UserBoard

  defp get_board(socket, board_id) do
    Enum.find(socket.assigns.user_boards, %UserBoard{}, fn ub ->
      ub.id == board_id
    end)
  end

  def assign_boards(socket) do
    assign(socket, :user_boards, Board.list_user_boards(socket.assigns.current_user.id))
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(_, _, socket) do
    {
      :noreply,
      socket
      |> assign_boards()
      |> assign(:new_name, "")
      |> assign(:editable_board, nil)
      |> assign(:page_title, "Board Settings")
    }
  end

  @impl Phoenix.LiveView
  def handle_event("edit", %{"id" => id}, socket) do
    id = Purple.parse_int(id)
    last_edited = socket.assigns.editable_board

    if last_edited && last_edited.id == id do
      {:noreply, assign(socket, :editable_board, nil)}
    else
      {:noreply, assign(socket, :editable_board, get_board(socket, id))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("new", _, socket) do
    if socket.assigns.new_name != "" do
      Board.create_user_board(%UserBoard{
        name: socket.assigns.new_name,
        user_id: socket.assigns.current_user.id
      })

      {
        :noreply,
        socket
        |> assign_boards()
        |> assign_side_nav()
      }
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("change_new_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :new_name, name)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Board.delete_user_board!(id)

    {
      :noreply,
      socket
      |> assign_boards()
      |> put_flash(:info, "Deleted board")
      |> assign_side_nav()
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:saved_board, _id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Board saved")
      |> assign(:editable_board, nil)
      |> assign_boards()
      |> assign_side_nav()
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:tag_change, _}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Updated tags")
      |> assign_boards()
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <form phx-submit="new" class="sm:w-1/3">
      <div class="flex flex-col mb-2">
        <input
          type="text"
          name="name"
          phx-change="change_new_name"
          value={@new_name}
          placeholder="New board name"
        />
      </div>
      <button class="btn mb-2" type="button" phx-click="new">
        Save
      </button>
    </form>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <%= for user_board <- @user_boards do %>
        <section class="mb-2 window">
          <div class="bg-purple-300 inline-links">
            <h2 class="ml-2 mb-2 inline"><%= user_board.name %></h2>
            <%= live_redirect(
              "View",
              to: user_board_path(user_board.id)
            ) %>
            <span>|</span>
            <%= link(
              if(@editable_board && @editable_board.id == user_board.id, do: "Cancel", else: "Edit"),
              phx_click: "edit",
              phx_value_id: user_board.id,
              to: "#"
            ) %>
            <span>|</span>
            <%= link("Delete",
              phx_click: "delete",
              phx_value_id: user_board.id,
              data: [confirm: "Are you sure?"],
              to: "#"
            ) %>
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
              <div class="mb-2">
                Is default? <%= user_board.is_default %>
              </div>
            </div>
          <% end %>
        </section>
      <% end %>
    </div>
    """
  end
end
