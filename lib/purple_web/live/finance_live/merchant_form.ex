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
      |> assign(:form, to_form(Finance.change_merchant(merchant)))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"merchant" => merchant_params}, socket) do
    form =
      socket.assigns.merchant
      |> Finance.change_merchant(merchant_params)
      |> to_form

    {
      :noreply,
      socket
      |> assign(:form, form)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"merchant" => merchant_params}, socket) do
    case save_merchant(socket, socket.assigns.action, merchant_params) do
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
      <.form for={@form} phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="flex flex-col mb-2">
          <.input
            field={@form[:category]}
            label="Category"
            type="select"
            options={Finance.category_mappings()}
          />
          <.input field={@form[:description]} type="textarea" rows={@rows} label="Description" />
        </div>
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end
end
