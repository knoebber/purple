defmodule PurpleWeb.FinanceLive.PaymentMethodForm do
  use PurpleWeb, :live_component

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
        send(self(), {:saved_payment_method, payment_method.id})
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
          <.input field={f[:name]} phx-hook="AutoFocus" label="Name" />
        </div>
        <.button phx-disable-with="Saving...">Save</.button>
      </.form>
    </div>
    """
  end
end
