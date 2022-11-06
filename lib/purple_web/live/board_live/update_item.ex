defmodule PurpleWeb.BoardLive.UpdateItem do
  @moduledoc """
  Form for updating items
  """

  use PurpleWeb, :live_component
  alias Purple.Board

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
    case Board.update_item(socket.assigns.item, item_params) do
      {:ok, _} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Item updated")
          |> push_patch(to: socket.assigns.return_to, replace: true)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset =
      socket.assigns.item
      |> Board.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :status) %>
          <%= select(f, :status, Board.item_status_mappings()) %>
          <%= error_tag(f, :status) %>
          <%= label(f, :description) %>
          <%= text_input(f, :description, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :description) %>
          <%= if Ecto.Changeset.get_field(@changeset, :status) == :TODO do %>
            <%= label(f, :priority) %>
            <%= select(f, :priority, 1..5) %>
            <%= error_tag(f, :priority) %>
          <% end %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
