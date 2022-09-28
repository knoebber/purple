defmodule PurpleWeb.FinanceLive.MerchantForm do
  use PurpleWeb, :live_component

  alias Purple.Finance

  defp save_merchant(socket, :edit_merchant, params) do
    Finance.update_merchant(socket.assigns.merchant, params)
  end

  defp save_merchant(_, :new_merchant, params) do
    Finance.create_merchant(params)
  end

  @impl Phoenix.LiveComponent
  def update(%{merchant: merchant} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:rows, text_area_rows(merchant.description))
      |> assign(:changeset, Finance.change_merchant(merchant))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"merchant" => merchant}, socket) do
    case save_merchant(socket, socket.assigns.action, merchant) do
      {:ok, merchant} ->
        Purple.Tags.sync_tags(merchant.id, :merchant)
        send(self(), {:saved_merchant, merchant.id})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@changeset} phx-submit="save" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <%= label(f, :name) %>
          <%= text_input(f, :name, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :name) %>
          <%= label(f, :description) %>
          <%= textarea(f, :description, rows: @rows) %>
          <%= error_tag(f, :description) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
