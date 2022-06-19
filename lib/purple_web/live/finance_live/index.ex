defmodule PurpleWeb.FinanceLive.Index do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}

  defp apply_action(socket, :edit_transaction, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Transaction")
    |> assign(:transaction, Finance.get_transaction!(id))
  end

  defp apply_action(socket, :new_transaction, _params) do
    socket
    |> assign(:page_title, "New Transaction")
    |> assign(:transaction, %Transaction{})
  end

  defp apply_action(socket, :new_merchant, _params) do
    socket
    |> assign(:page_title, "New Merchant")
    |> assign(:merchant, %Merchant{})
  end

  defp apply_action(socket, :edit_merchant, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Merchant")
    |> assign(:merchant, Finance.get_merchant!(id))
  end

  defp apply_action(socket, :new_payment_method, _params) do
    socket
    |> assign(:page_title, "New Payment Method")
    |> assign(:payment_method, %PaymentMethod{})
  end

  defp apply_action(socket, :edit_payment_method, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Payment Method")
    |> assign(:payment_method, Finance.get_payment_method!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Finance")
    |> assign(:transaction, nil)
  end

  defp assign_finance_data(socket) do
    filter = Purple.Filter.clean_filter(socket.assigns.filter)

    socket
    |> assign(:transactions, Finance.list_transactions(filter))
    |> assign(:merchant_options, Finance.merchant_mappings())
    |> assign(:payment_method_options, Finance.payment_method_mappings())
    |> assign(:tag_options, Purple.Filter.make_tag_select_options(:transaction, filter))
  end

  defp get_action(%{"action" => action, "id" => _})
       when action in [
              "edit_transaction",
              "edit_merchant",
              "edit_payment_method"
            ] do
    String.to_atom(action)
  end

  defp get_action(%{"action" => action})
       when action in [
              "new_transaction",
              "new_merchant",
              "new_payment_method"
            ] do
    String.to_atom(action)
  end

  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    action = get_action(params)

    filter =
      Purple.Filter.make_filter(
        params,
        %Purple.Filter{user_id: socket.assigns.current_user.id}
      )

    {
      :noreply,
      socket
      |> assign(:filter, filter)
      |> assign(:params, params)
      |> assign(:action, action)
      |> assign_finance_data()
      |> apply_action(action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => params}, socket) do
    {:noreply, push_patch(socket, to: index_path(params), replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    Finance.get_transaction!(id) |> Finance.delete_transaction!()

    {:noreply, assign_finance_data(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1>Transactions</h1>
    </div>
    <%= cond do %>
      <% @action in [:new_transaction, :edit_transaction] -> %>
        <.modal title={@page_title} return_to={index_path(@params)}>
          <.live_component
            action={@action}
            current_user={@current_user}
            id={@transaction.id || :new}
            merchant_options={@merchant_options}
            module={PurpleWeb.FinanceLive.TransactionForm}
            params={@params}
            payment_method_options={@payment_method_options}
            transaction={@transaction}
          />
        </.modal>
      <% @action in [:new_merchant, :edit_merchant] -> %>
        <.modal title={@page_title} return_to={index_path(@params)}>
          <.live_component
            action={@action}
            id={@merchant.id || :new}
            merchant={@merchant}
            module={PurpleWeb.FinanceLive.MerchantForm}
            params={@params}
          />
        </.modal>
      <% @action in [:new_payment_method, :edit_payment_method] -> %>
        <.modal title={@page_title} return_to={index_path(@params)}>
          <.live_component
            action={@action}
            id={@payment_method.id || :new}
            module={PurpleWeb.FinanceLive.PaymentMethodForm}
            params={@params}
            payment_method={@payment_method}
          />
        </.modal>
      <% true -> %>
    <% end %>
    <.form
      class="table-filters"
      for={@filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      <%= text_input(f, :query, placeholder: "Search...", phx_debounce: "200") %>
      <%= select(f, :tag, @tag_options) %>
      <%= select(
        f,
        :merchant,
        [[value: "", key: "🧟‍♀️ All merchants"]] ++ @merchant_options
      ) %>
      <%= select(
        f,
        :payment_method,
        [[value: "", key: "💸 All payment methods"]] ++ @payment_method_options
      ) %>
    </.form>
    <.table rows={@transactions}>
      <:col let={transaction} label="Amount">
        <%= transaction.amount %>
      </:col>
      <:col let={transaction} label="Timestamp">
        <%= format_date(transaction.timestamp) %>
      </:col>
      <:col let={transaction} label="Merchant">
        <%= transaction.merchant.name %>
      </:col>
      <:col let={transaction} label="Payment Method">
        <%= transaction.payment_method.name %>
      </:col>
      <:col let={transaction} label="">
        <%= live_patch("Edit", to: index_path(@params, :edit_transaction, transaction.id)) %>
      </:col>
      <:col let={transaction} label="">
        <%= link("Delete",
          phx_click: "delete",
          phx_value_id: transaction.id,
          data: [confirm: "Are you sure?"],
          to: "#"
        ) %>
      </:col>
    </.table>
    """
  end
end
