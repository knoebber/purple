defmodule PurpleWeb.BoardLive.EntryForm do
  @moduledoc """
  Form for updating an item entry
  """

  use PurpleWeb, :live_component
  alias Purple.Board

  defp save(socket, %{"content" => ""}), do: socket

  defp save(socket, params) do
    {:ok, entry} = Board.update_item_entry(socket.assigns.entry, params)
    assign(socket, :entry, entry)
  end

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
    {:noreply,
     socket
     |> save(params)
     |> push_patch(to: socket.assigns.return_to, replace: true)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("autosave", %{"item_entry" => params}, socket) do
    # TODO: on cancel, revert to last version.
    {:noreply, save(socket, params)}
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
        phx-debounce="5000"
        phx-target={@myself}
        class="p-4"
      >
        <div class="flex flex-col mb-2">
          <.input field={{f, :item_id}} type="hidden" value={@item_id} />
          <.input field={{f, :is_collapsed}} type="hidden" value={false} />
          <.input field={{f, :content}} type="textarea" rows={@num_rows} phx-hook="MarkdownTextarea" />
        </div>
        <.button>Done</.button>
      </.form>
    </div>
    """
  end
end
