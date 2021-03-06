defmodule PurpleWeb.BoardLive.ItemForm do
  use PurpleWeb, :live_component

  alias Purple.Board

  defp save_item(socket, :edit_item, params), do: Board.update_item(socket.assigns.item, params)
  defp save_item(_, :new_item, params), do: Board.create_item(params)

  @impl Phoenix.LiveComponent
  def update(%{item: item} = assigns, socket) do
    changeset = Board.change_item(item)

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"item" => item_params}, socket) do
    case save_item(socket, socket.assigns.action, item_params) do
      {:ok, item} ->
        Purple.Tags.sync_tags(item.id, :item)

        {
          :noreply,
          socket
          |> put_flash(:info, "Item saved")
          |> push_patch(to: socket.assigns.return_to)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :status) %>
          <%= select(f, :status, Board.item_status_mappings()) %>
          <%= error_tag(f, :status) %>
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
