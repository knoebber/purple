defmodule PetallerWeb.BoardLive.ItemEntryForm do
  use PetallerWeb, :live_component

  alias Petaller.Board

  @impl true
  def update(%{entry: entry} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, Board.change_item_entry(entry))}
  end

  @impl true
  def handle_event("save", %{"item_entry" => params}, socket) do
    send(self(), {:updated_item_entry, socket.assigns.entry, params})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= hidden_input(f, :item_id, value: @item_id) %>
          <%= label(f, :content) %>
          <%= textarea(f, :content) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </section>
    """
  end
end
