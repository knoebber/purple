defmodule PurpleWeb.FinanceLive.SharedTransactionForm do
  use PurpleWeb, :live_component
  alias Purple.Finance

  defp save(socket, :edit, params) do
    Finance.update_shared_transaction(socket.assigns.shared_transaction, params)
  end

  defp save(socket, :new, params) do
    Finance.create_shared_transaction(
      socket.assigns.shared_budget_id,
      params
    )
  end

  defp assign_data(socket) do
    assign(
      socket,
      :changeset,
      Finance.change_shared_transaction(socket.assigns.shared_transaction)
    )
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"shared_transaction" => params}, socket) do
    case save(socket, socket.assigns.action, params) do
      {:ok, _} ->
        send(self(), :new_shared_transaction)
        {:noreply, assign_data(socket)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="mb-2">
      <.form :let={f} for={@changeset} class="grid grid-cols-3 grid-rows-1 gap-2" phx-submit="save" phx-target={@myself}>
        <.input
          field={{f, :transaction_id}}
          label="Transaction"
          type="select"
          options={@user_transaction_mappings}
        />
        <.input
          field={{f, :type}}
          label="Type"
          type="select"
          options={Finance.share_type_mappings()}
        />
        <div class="flex">
          <.button class="h-2/3 self-end">Add</.button>
        </div>
      </.form>
    </div>
    """
  end
end
