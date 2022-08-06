defmodule PurpleWeb.BoardLive.CreateItem do
  @moduledoc """
  Item form that's only for creation.
  """

  use PurpleWeb, :live_view

  import PurpleWeb.BoardLive.BoardHelpers

  alias Purple.Board
  alias Purple.Board.{Item, ItemEntry, UserBoard}

  defp assign_changeset(socket, default_entry) do
    entries = [%ItemEntry{content: default_entry}]

    entries =
      if default_entry != "" do
        [%ItemEntry{content: ""}] ++ entries
      end

    assign(socket, :changeset, Board.change_item(%Item{entries: entries}))
  end

  defp user_board_entry(%UserBoard{tags: []}) do
    ""
  end

  defp user_board_entry(ub = %UserBoard{}) do
    "Created for [#{ub.name}](#{index_path(ub.id)})\n---\n" <>
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
        Board.get_user_board!(board_id)
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
        Purple.Tags.sync_tags(item.id, :item)

        {:noreply, push_redirect(socket, to: show_item_path(item))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.form for={@changeset} let={f} phx-submit="save">
      <div class="flex flex-col mb-2">
        <%= label(f, :description) %>
        <%= text_input(f, :description, phx_hook: "AutoFocus") %>
        <%= error_tag(f, :description) %>
        <%= label(f, :priority) %>
        <%= select(f, :priority, 1..5) %>
        <%= error_tag(f, :priority) %>
        <%= inputs_for f, :entries, fn entry -> %>
          <%= label(entry, :entry) %>
          <%= textarea(entry, :content, rows: 3) %>
          <%= error_tag(entry, :content) %>
        <% end %>
      </div>
      <%= submit("Save", phx_disable_with: "Saving...") %>
    </.form>
    """
  end
end
