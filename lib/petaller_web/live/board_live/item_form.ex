defmodule PetallerWeb.BoardLive.ItemForm do
  use PetallerWeb, :live_component

  alias Petaller.Board

  defp save_item(socket, :edit_item, params) do
    case Board.update_item(socket.assigns.item, params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item updated")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_item(socket, :new_item, params) do
    case Board.create_item(params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item created")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    changeset = Board.change_item(item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :description) %>
          <%= text_input(f, :description, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :description) %>
          <%= label(f, :priority) %>
          <%= select(f, :priority, 1..5) %>
          <%= error_tag(f, :priority) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
