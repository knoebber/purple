defmodule PurpleWeb.BoardLive.BoardSettings do
  @moduledoc """
  Live view for managing user's boards.
  """

  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.UserBoard
  alias PurpleWeb.Markdown

  def assign_boards(socket) do
    assign(socket, :user_boards, Board.list_user_boards(socket.assigns.current_user.id))
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav(socket.assigns.current_user.id))}
  end

  @impl Phoenix.LiveView
  def handle_params(_, _, socket) do
    {
      :noreply,
      socket
      |> assign_boards()
      |> assign(:new_name, "")
      |> assign(:page_title, "Board Settings")
    }
  end

  @impl Phoenix.LiveView
  def handle_event("new", _, socket) do
    if socket.assigns.new_name != "" do
      Board.create_user_board!(%UserBoard{
        name: socket.assigns.new_name,
        user_id: socket.assigns.current_user.id
      })

      {:noreply, assign_boards(socket)}
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
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>
    <form phx-submit="new" class="sm:w-1/3">
      <div class="flex flex-col mb-2">
        <input type="text" name="name" phx-change="change_new_name" value={@new_name} />
      </div>
      <button class="btn mb-2" type="button" phx-click="new">
        Save
      </button>
    </form>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <%= for user_board <- @user_boards do %>
        <section class="p-4 mt-2 mb-2 window">
          <h2 class="mb-2"><%= user_board.name %></h2>
          <div class="mb-2">
            Tags: [
            <%= for tag <- user_board.tags do %>
              <%= tag.name %>
            <% end %>
            ]
          </div>
          <div class="mb-2">
            Show done? <%= user_board.show_done %>
          </div>
          <div class="mb-2">
            Is default? <%= user_board.is_default %>
          </div>
          <div class="mb-2">
            <%= link("Delete",
              phx_click: "delete",
              phx_value_id: user_board.id,
              data: [confirm: "Are you sure?"],
              to: "#"
            ) %>
          </div>
        </section>
      <% end %>
    </div>
    """
  end
end
