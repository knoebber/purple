defmodule PetallerWeb.BoardLive.ItemEntryForm do
  use PetallerWeb, :live_component

  alias Petaller.Board

  defp save_item_entry(socket, :edit, params) do
    case Board.update_item_entry(socket.assigns.item, params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry updated")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_item_entry(socket, :new, params) do
    case Board.create_item_entry(params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Entry created")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def update(%{item_entry: item_entry} = assigns, socket) do
    changeset = Board.change_item_entry(item_entry)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"item_entry" => params}, socket) do
    save_item_entry(socket, socket.assigns.action, params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h2><%= @title %></h2>
      <.form for={@changeset} id="item-form" let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :description) %>
          <%= textarea(f, :description) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </section>
    """
  end
end
