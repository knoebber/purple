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
  def handle_event("validate", _, socket) do
    {:noreply, socket}
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
    <div class={@class}>
      <.form :let={f} for={@changeset} phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <.input field={f[:name]} phx-hook="AutoFocus" label="Name" />
          <.input
            field={f[:category]}
            label="Category"
            type="select"
            options={Finance.category_mappings()}
          />
          <.input field={f[:description]} type="textarea" rows={@rows} label="Description" />
        </div>
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end
end
