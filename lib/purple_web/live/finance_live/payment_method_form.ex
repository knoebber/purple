defmodule PurpleWeb.FinanceLive.PaymentMethodForm do
  use PurpleWeb, :live_component

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp save_payment_method(socket, :edit_payment_method, params) do
    Finance.update_payment_method(socket.assigns.payment_method, params)
  end

  defp save_payment_method(_, :new_payment_method, params) do
    Finance.create_payment_method(params)
  end

  @impl Phoenix.LiveComponent
  def update(%{payment_method: payment_method} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:changeset, Finance.change_payment_method(payment_method))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"payment_method" => payment_method}, socket) do
    case save_payment_method(socket, socket.assigns.action, payment_method) do
      {:ok, payment_method} ->
        params =
          Map.merge(
            socket.assigns.params,
            %{payment_method_id: payment_method.id}
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
          |> put_flash(:info, "Payment method saved")
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
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
