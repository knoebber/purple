defmodule PurpleWeb.BoardLive.UserBoardForm do
  @moduledoc """
  Form for updating rows in the user_boards database table.
  """

  use PurpleWeb, :live_component

  alias Purple.{Board, Tags}

  defp save_board(socket, :edit_board, params) do
    Board.update_user_board(socket.assigns.user_board, params)
  end

  defp save_board(_, :new_board, params) do
    Board.create_user_board(params)
  end

  @impl Phoenix.LiveComponent
  def update(%{user_board: user_board} = assigns, socket) do
    changeset = Board.change_user_board(user_board)

    available_tags =
      Enum.reject(
        Tags.list_tags(:item),
        fn new_tag ->
          Enum.find(
            user_board.tags,
            fn existing_tag -> existing_tag.id == new_tag.id end
          )
        end
      )

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
      |> assign(:available_tags, available_tags)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_tag", params, socket) do
    user_board_id = socket.assigns.user_board.id
    tag_id = Purple.int_from_map(params, "tag_id")

    if is_integer(tag_id) do
      Board.add_user_board_tag(user_board_id, tag_id)
      send(self(), {:tag_change, user_board_id})
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_tag", params, socket) do
    user_board_id = socket.assigns.user_board.id
    tag_id = Purple.int_from_map(params, "id")
    Board.delete_user_board_tag!(user_board_id, tag_id)
    send(self(), {:tag_change, user_board_id})
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"user_board" => params}, socket) do
    case save_board(socket, :edit_board, params) do
      {:ok, board} ->
        send(self(), {:saved_board, board.id})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <%= if length(@available_tags) > 0 do %>
        <form class="flex flex-row mb-2" phx-submit="add_tag" phx-target={@myself}>
          <select name="tag_id">
            <option value="">🏷 Select a tag</option>
            <%= for tag <- @available_tags do %>
              <option value={tag.id}>
                #<%= tag.name %>
              </option>
            <% end %>
          </select>
          <button class="ml-3" type="submit">Add</button>
        </form>
      <% end %>
      <%= if length(@user_board.tags) > 0 do %>
        <ul class="ml-4">
          <%= for tag <- @user_board.tags do %>
            <li>
              <code class="inline">#<%= tag.name %></code>
              <%= link("Remove",
                phx_click: "remove_tag",
                phx_target: @myself,
                phx_value_id: tag.id,
                to: "#"
              ) %>
            </li>
          <% end %>
        </ul>
      <% end %>

      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :name) %>
          <%= text_input(f, :name, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :name) %>
          <%= label(f, :show_done) %>
          <%= checkbox(f, :show_done) %>
          <%= error_tag(f, :show_done) %>
        </div>
        <%= submit("Update", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
