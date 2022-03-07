defmodule PetallerWeb.ItemLive.FormComponent do
  use PetallerWeb, :live_component

  alias Petaller.Items

  defp save_item(socket, :edit, item_params) do
    case Items.update(socket.assigns.item, item_params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item updated")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_item(socket, :new, item_params) do
    case Items.create(item_params) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item created")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def update(%{item: item} = assigns, socket) do
    changeset = Items.change(item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.action, item_params)
  end

  def render(assigns) do
    ~H"""
    <section>
      <h2><%= @title %></h2>
      <.form for={@changeset} id="item-form" let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :description) %>
          <%= text_input(f, :description) %>
          <%= label(f, :priority) %>
          <%= select(f, :priority, 1..5) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </section>
    """
  end
end
