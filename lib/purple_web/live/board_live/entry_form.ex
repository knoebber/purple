defmodule PurpleWeb.BoardLive.EntryForm do
  @moduledoc """
  Form for updating an item entry
  """

  use PurpleWeb, :live_component
  alias Purple.Board

  @impl Phoenix.LiveComponent
  def update(%{entry: entry} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Board.change_item_entry(entry))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("done", %{"item_entry" => params}, socket) do
    socket =
      case Board.update_item_entry(socket.assigns.entry, params) do
        {:ok, _} -> push_patch(socket, to: socket.assigns.return_to, replace: true)
        {:error, changeset} -> assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("autosave", %{"item_entry" => params}, socket) do
    socket =
      case Board.update_item_entry(socket.assigns.entry, params) do
        {:ok, entry} ->
          socket
          |> assign(:changeset, Board.change_item_entry(entry))
          |> assign(:entry, entry)

        {:error, changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        phx-submit="done"
        phx-change="autosave"
        phx-target={@myself}
        class="p-4"
      >
        <div class="flex flex-col mb-2">
          <.input field={{f, :item_id}} type="hidden" value={@item_id} />
          <.input field={{f, :is_collapsed}} type="hidden" value={false} />
          <.input
            field={{f, :content}}
            phx-debounce="1000"
            phx-hook="MarkdownTextarea"
            rows={@num_rows}
            type="textarea"
          />
        </div>
        <.button>Done</.button>
      </.form>
    </div>
    """
  end
end
