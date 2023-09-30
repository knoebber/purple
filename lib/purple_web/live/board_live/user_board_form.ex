defmodule PurpleWeb.BoardLive.UserBoardForm do
  @moduledoc """
  Form for updating rows in the user_boards database table.
  """

  use PurpleWeb, :live_component

  alias Purple.{Board, Tags}

  defp update_param_tags(params, changeset) do
    # Form sends tags param in a different format than changeset expects
    Map.put(params, "tags", Ecto.Changeset.fetch_field!(changeset, :tags))
  end

  defp save_board(socket, :edit, params) do
    Board.update_user_board(
      socket.assigns.user_board,
      update_param_tags(params, socket.assigns.changeset)
    )
  end

  defp save_board(socket, :create, params) do
    Board.create_user_board(
      update_param_tags(params, socket.assigns.changeset),
      socket.assigns.current_user.id
    )
  end

  defp assign_available_tags(socket) do
    assign(
      socket,
      :available_tags,
      Tags.list_tags_not_in(
        :item,
        Enum.map(Ecto.Changeset.fetch_field!(socket.assigns.changeset, :tags), & &1.name)
      )
    )
  end

  defp assign_changeset_tag_assoc(socket, new_tags) do
    assign(
      socket,
      :changeset,
      Ecto.Changeset.put_assoc(
        socket.assigns.changeset,
        :tags,
        new_tags
      )
    )
  end

  @impl Phoenix.LiveComponent
  def update(%{user_board: user_board} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Board.change_user_board(user_board, %{"tags" => user_board.tags}))
      |> assign_available_tags()
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_tag", %{"id" => id}, socket) do
    current_tags = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :tags)
    id_to_add = Purple.parse_int!(id)

    tag_to_add =
      Enum.find(
        socket.assigns.available_tags,
        &(&1.id == id_to_add)
      )

    {
      :noreply,
      socket
      |> assign_changeset_tag_assoc([tag_to_add | current_tags])
      |> assign_available_tags
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_tag", %{"id" => id}, socket) do
    current_tags = Ecto.Changeset.fetch_field!(socket.assigns.changeset, :tags)
    id_to_remove = Purple.parse_int!(id)

    {
      :noreply,
      socket
      |> assign_changeset_tag_assoc(Enum.reject(current_tags, &(&1.id == id_to_remove)))
      |> assign_available_tags()
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"user_board" => params}, socket) do
    {
      :noreply,
      assign(
        socket,
        :changeset,
        Board.change_user_board(
          socket.assigns.user_board,
          update_param_tags(params, socket.assigns.changeset)
        )
      )
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"user_board" => params}, socket) do
    case save_board(socket, socket.assigns.action, params) do
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
      <.form
        :let={f}
        for={@changeset}
        phx-submit="save"
        phx-target={@myself}
        phx-change="validate"
        phx-debounce="500"
      >
        <div class="flex flex-col gap-4 mb-4">
          <.input field={f[:name]} phx-hook="AutoFocus" label="Name" />
          <.label>Tags</.label>
          <div class="flex flex-wrap text-xs font-mono gap-1 max-h-48 overflow-auto">
            <.button
              :for={tag <- @available_tags}
              phx-click="add_tag"
              phx-value-id={tag.id}
              phx-target={@myself}
              type="button"
            >
              <%= tag.name %>
            </.button>
          </div>
          <.inputs_for :let={tag} field={f[:tags]} skip_hidden={true}>
            <div class="flex gap-4">
              <.input field={tag[:name]} readonly />
              <button
                phx-click="remove_tag"
                phx-value-id={tag[:id].value}
                phx-target={@myself}
                type="button"
              >
                ❌
              </button>
            </div>
          </.inputs_for>
        </div>
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end
end
