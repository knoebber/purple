defmodule PurpleWeb.FinanceLive.TransactionForm do
  use PurpleWeb, :live_component

  # TODO: This component could show all shared adjustments in the SB. Then a form at top.
  # The form should let you choose which user to add an adjustment for.
  # Table of adjustments like:
  # |email | amount | description | created

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp save_transaction(socket, :edit_transaction, params) do
    Finance.update_transaction(socket.assigns.transaction, params)
  end

  defp save_transaction(socket, :new_transaction, params) do
    Finance.create_transaction(socket.assigns.current_user.id, params)
  end

  defp selected_option_id(_, [], _), do: 0

  defp selected_option_id(changeset, options, field) do
    case Ecto.Changeset.get_field(changeset, field) do
      nil ->
        {:value, id} = hd(hd(options))
        id

      val ->
        val
    end
  end

  defp should_leave_open?(params) do
    Map.get(params, "should_leave_open") == "on"
  end

  defp assign_changeset(socket, params) do
    assigns = socket.assigns
    changeset = Finance.change_transaction(assigns.transaction, params)
    merchant_id = selected_option_id(changeset, assigns.merchant_options, :merchant_id)

    payment_method_id =
      selected_option_id(changeset, assigns.payment_method_options, :payment_method_id)

    socket
    |> assign(:changeset, changeset)
    |> assign(:merchant_id, merchant_id)
    |> assign(:payment_method_id, payment_method_id)
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:rows, text_area_rows(assigns.transaction.notes))
      |> assign_changeset(assigns.params)
      |> assign(:should_leave_open, false)
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", params = %{"transaction" => tx_params}, socket) do
    {
      :noreply,
      socket
      |> assign_changeset(tx_params)
      |> assign(:should_leave_open, should_leave_open?(params))
    }
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", params = %{"transaction" => tx_params}, socket) do
    case save_transaction(socket, socket.assigns.action, tx_params) do
      {:ok, transaction} ->
        Purple.Tags.sync_tags(transaction.id, :transaction)

        next_path =
          if should_leave_open?(params) do
            index_path(socket.assigns.params, :new_transaction)
          else
            index_path(socket.assigns.params)
          end

        {
          :noreply,
          socket
          |> put_flash(:info, "Transaction saved")
          |> push_patch(to: next_path)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@changeset} let={f} phx-submit="save" phx-target={@myself} phx-change="validate">
        <div class="flex flex-col mb-2">
          <%= label(f, :description) %>
          <%= text_input(f, :description, rows: @rows) %>
          <%= error_tag(f, :description) %>
          <%= label(f, :dollars, "Amount") %>
          <%= text_input(f, :dollars, phx_hook: "AutoFocus") %>
          <%= error_tag(f, :cents) %>
          <%= label(f, :timestamp, "Timestamp") %>
          <%= datetime_select_group(f, :timestamp) %>
          <%= error_tag(f, :timestamp) %>
          <%= label(f, :merchant_id, "Merchant") %>
          <div class="flex justify-between">
            <%= select(f, :merchant_id, @merchant_options, class: "w-5/6") %>
            <%= live_patch(
              to: index_path(@params, :edit_merchant, @id, @merchant_id),
              class: "text-xl self-center")
            do %>
              <button type="button" class="window p-1 bg-white">✏️</button>
            <% end %>
            <%= live_patch(
              to: index_path(@params, :new_merchant, @id),
              class: "text-xl self-center")
            do %>
              <button type="button" class="window p-1 bg-white">➕</button>
            <% end %>
          </div>
          <%= error_tag(f, :merchant_id) %>
          <%= label(f, :payment_method_id, "Payment Method") %>
          <div class="flex justify-between">
            <%= select(f, :payment_method_id, @payment_method_options, class: "w-5/6") %>
            <%= live_patch(
              to: index_path(@params, :edit_payment_method, @id, @payment_method_id),
              class: "text-xl self-center")
            do %>
              <button type="button" class="window p-1 bg-white">✏️</button>
            <% end %>
            <%= live_patch(
              to: index_path(@params, :new_payment_method, @id),
              class: "text-xl self-center")
            do %>
              <button type="button" class="window p-1 bg-white">➕</button>
            <% end %>
          </div>
          <%= error_tag(f, :payment_method_id) %>
          <%= label(f, :notes) %>
          <%= textarea(f, :notes, rows: @rows) %>
          <%= error_tag(f, :notes) %>
        </div>
        <div class="flex justify-between">
          <%= submit("Save", phx_disable_with: "Saving...") %>
          <%= if @action == :new_transaction do %>
            <div class="self-center">
              <label for="should_leave_open">Create Another?</label>
              <input type="checkbox" name="should_leave_open" checked={@should_leave_open} />
            </div>
          <% end %>
        </div>
      </.form>
    </div>
    """
  end
end
