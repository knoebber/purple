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
      else
        entries
      end

    assign(socket, :changeset, Board.change_item(%Item{entries: entries}))
  end

  defp user_board_entry(%UserBoard{tags: []}) do
    ""
  end

  defp user_board_entry(ub = %UserBoard{}) do
    # TODO: add full path and add fancy link impl for user board view.
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
        {:noreply, push_redirect(socket, to: show_item_path(item))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:error, :rollback} ->
        {:noreply,
         socket
         |> assign(:changeset, Board.change_item(%Item{}, params))
         |> put_flash(:error, "Failed to create item")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"item" => params}, socket) do
    changeset =
      %Item{}
      |> Board.change_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.form :let={f} for={@changeset} phx-submit="save" phx-change="validate">
      <div class="flex flex-col mb-2 w-full xl:w-1/2">
        <.input field={{f, :description}} phx-hook="AutoFocus" />
        <.input
          :if={Ecto.Changeset.get_field(@changeset, :status) == :TODO}
          type="select"
          field={{f, :priority}}
          options={1..5}
        />
        <.input field={{f, :status}} type="select" options={Board.item_status_mappings()} />
        <%= Phoenix.HTML.inputs_for f, :entries, fn entry -> %>
          <.input field={{entry, :entry}} type="textarea" , rows="3" />
        <% end %>
      </div>
      <.button phx-disable-with="Saving...">Save</.button>
    </.form>
    """
  end
end
