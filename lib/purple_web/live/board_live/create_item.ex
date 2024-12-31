defmodule PurpleWeb.BoardLive.CreateItem do
  @moduledoc """
  Item form that's only for creation.
  """
  alias Purple.Board
  alias Purple.Board.{Item, ItemEntry, UserBoard}
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  defp assign_changeset(socket, default_entry) do
    entries = [%ItemEntry{content: default_entry, sort_order: 1}]

    entries =
      if default_entry != "" do
        [%ItemEntry{content: "", sort_order: 0}] ++ entries
      else
        entries
      end

    assign(socket, :changeset, Board.change_item(%Item{entries: entries}))
  end

  defp user_board_entry(%UserBoard{tags: []}) do
    ""
  end

  defp user_board_entry(ub = %UserBoard{}) do
    Enum.map_join(ub.tags, " ", &("#" <> &1.name))
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign_side_nav
      |> assign(:page_title, "Create Item")
    }
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    board_id = Purple.int_from_map(params, "user_board_id")

    user_board =
      if board_id do
        Board.get_user_board(board_id)
      else
        %UserBoard{tags: []}
      end

    {:noreply, assign_changeset(socket, user_board_entry(user_board))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"item" => params}, socket) do
    params =
      Map.put(
        params,
        "entries",
        Map.reject(params["entries"], fn {_, entry} -> entry["content"] == "" end)
      )

    case Board.create_item(params) do
      {:ok, item} ->
        {:noreply, push_navigate(socket, to: ~p"/board/item/#{item}")}

      {:error, %Ecto.Changeset{data: %Board.Item{}} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, %Ecto.Changeset{data: %Board.ItemEntry{}}} ->
        {:noreply, put_flash(socket, :error, "Failed to create item. Check entry content")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">{@page_title}</h1>
    <.form :let={f} for={@changeset} phx-submit="save" phx-change="validate">
      <div class="flex flex-col mb-2 w-full xl:w-1/2">
        <.input field={f[:description]} phx-hook="AutoFocus" label="Description" />
        <.input
          field={f[:status]}
          type="select"
          options={Board.item_status_mappings()}
          label="Status"
        />
        <.inputs_for :let={fp} field={f[:entries]}>
          <.input field={fp[:content]} type="textarea" rows="3" label="Entry" />
        </.inputs_for>
      </div>
      <.button phx-disable-with="Saving...">Save</.button>
    </.form>
    """
  end
end
