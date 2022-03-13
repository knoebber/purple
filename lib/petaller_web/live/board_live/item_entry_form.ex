defmodule PetallerWeb.BoardLive.ItemEntryForm do
  use PetallerWeb, :live_component

  alias Petaller.Board
  alias Petaller.Board.ItemEntry

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Board.change_item_entry(%ItemEntry{}))}
  end

  @impl true
  def handle_event("save", %{"item_entry" => params}, socket) do
    IO.inspect(["entry save:", socket.assigns])
    send(self(), {:updated_item_entry, socket.assigns.entry, params})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= hidden_input(f, :item_id, value: @item_id) %>
          <%= label(f, :content) %>
          <%= textarea(f, :content) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
