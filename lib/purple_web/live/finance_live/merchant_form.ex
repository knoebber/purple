defmodule PurpleWeb.FinanceLive.MerchantForm do
  use PurpleWeb, :live_component

  import PurpleWeb.FinanceLive.FinanceHelpers

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

        params =
          Map.merge(
            socket.assigns.params,
            %{merchant_id: merchant.id}
          )

        transaction_id = Map.get(params, "transaction_id")

        return_to =
          if transaction_id do
            index_path(params, :edit_transaction, transaction_id)
          else
            index_path(params, :new_transaction)
          end

        {
          :noreply,
          socket
          |> put_flash(:info, "Merchant saved")
          |> push_patch(to: return_to)
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
