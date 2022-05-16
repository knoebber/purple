defmodule PurpleWeb.FinanceLive.TransactionForm do
  use PurpleWeb, :live_component

  import PurpleWeb.FinanceLive.Helpers

  alias Purple.Finance

  defp save_transaction(socket, :edit_transaction, params) do
    Finance.update_transaction(socket.assigns.transaction, params)
  end

  defp save_transaction(socket, :new_transaction, params) do
    Finance.create_transaction(socket.assigns.current_user.id, params)
  end

  @impl Phoenix.LiveComponent
  def update(%{transaction: transaction} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:rows, text_area_rows(transaction.description))
      |> assign(:changeset, Finance.change_transaction(transaction, assigns.params))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"transaction" => params}, socket) do
    case save_transaction(socket, socket.assigns.action, params) do
      {:ok, transaction} ->
        Purple.Tags.sync_tags(transaction.id, :transaction)

        {
          :noreply,
          socket
          |> put_flash(:info, "Transaction saved")
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
          <%= label(f, :cents, "Amount") %>
          <%= number_input(f, :cents) %>
          <%= error_tag(f, :cents) %>
          <%= label(f, :payment_method_id, "Payment Method") %>
          <div class="flex justify-between">
            <%= select(f, :payment_method_id, @payment_method_options, class: "w-5/6") %>
            <%= live_patch(
              to: index_path(@params, :new_payment_method),
              class: "text-xl self-center")
            do %>
              <button class="window p-1 bg-white">➕</button>
            <% end %>
          </div>
          <%= error_tag(f, :payment_method_id) %>
          <%= label(f, :merchant_id, "Merchant") %>
          <div class="flex justify-between">
            <%= select(f, :merchant_id, @merchant_options, class: "w-5/6") %>
            <%= live_patch(
              to: index_path(@params, :new_merchant),
              class: "text-xl self-center")
            do %>
              <button class="window p-1 bg-white">➕</button>
            <% end %>
          </div>
          <%= error_tag(f, :merchant_id) %>
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
