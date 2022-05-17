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
  def handle_event("save", %{"payment_method" => params}, socket) do
    case save_payment_method(socket, socket.assigns.action, params) do
      {:ok, payment_method} ->
        params = socket.assigns.params

        return_to =
          if socket.assigns.action == :new_payment_method do
            params
            |> Map.merge(%{payment_method_id: payment_method.id})
            |> index_path(:new_transaction)
          else
            index_path(params)
          end

        {
          :noreply,
          socket
          |> put_flash(:info, "Payment_Method saved")
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
          <%= text_input(f, :name) %>
          <%= error_tag(f, :name) %>
        </div>
        <%= submit("Save", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end
end
