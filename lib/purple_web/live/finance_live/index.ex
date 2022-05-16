defmodule PurpleWeb.FinanceLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Finance
  alias Purple.Finance.Transaction

  defp index_path(params, new_params = %{}) do
    Routes.finance_index_path(PurpleWeb.Endpoint, :index, Map.merge(params, new_params))
  end

  defp index_path(params, :new_transaction) do
    index_path(params, %{action: "new_transaction"})
  end

  defp index_path(params, :edit_transaction, transaction_id) do
    index_path(params, %{action: "edit_transaction", id: transaction_id})
  end

  defp index_path(params) do
    index_path(
      Map.reject(
        params,
        fn {key, val} -> key in ["action", "id"] or val == "" end
      ),
      %{}
    )
  end

  defp apply_action(socket, :edit_transaction, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Transaction #{id}")
    |> assign(:transaction, Finance.get_transaction!(id))
  end

  defp apply_action(socket, :new_transaction, _params) do
    socket
    |> assign(:page_title, "New Transaction")
    |> assign(:transaction, %Transaction{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Finance")
    |> assign(:transaction, nil)
  end

  defp assign_finance_data(socket) do
    filter = socket.assigns.filter.changes

    socket
    |> assign(:transactions, Finance.list_transactions(filter))
    |> assign(:merchant_options, Finance.merchant_mappings())
    |> assign(:payment_method_options, Finance.payment_method_mappings())
    |> assign(:tag_options, Purple.Filter.make_tag_select_options(:transaction))
  end

  defp get_action(%{"action" => "edit_transaction", "id" => _}), do: :edit_transaction
  defp get_action(%{"action" => "new_transaction"}), do: :new_transaction
  defp get_action(_), do: :index

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    action = get_action(params)

    {
      :noreply,
      socket
      |> assign(:filter, Purple.Filter.make_filter(params))
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
      <%= live_patch(
        to: index_path(@params, :new_transaction),
        class: "text-xl self-end ml-1")
      do %>
        <button>➕</button>
      <% end %>
    </div>
    <%= if @action in [:new_transaction, :edit_transaction] do %>
      <.modal title={@page_title} return_to={index_path(@params)}>
        <.live_component
          action={@action}
          current_user={@current_user}
          id={@transaction.id || :new}
          merchant_options={@merchant_options}
          module={PurpleWeb.FinanceLive.TransactionForm}
          payment_method_options={@payment_method_options}
          return_to={index_path(@params)}
          transaction={@transaction}
        />
      </.modal>
    <% end %>
    <.form
      class="flex mb-2 gap-1"
      for={@filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      <%= text_input(f, :query, placeholder: "Search...", phx_debounce: "200") %>
      <%= select(f, :tag, @tag_options) %>
    </.form>
    <table class="window">
      <thead class="bg-purple-300">
        <tr>
          <th>Amount</th>
          <th>Timestamp</th>
        </tr>
      </thead>
      <tbody>
        <%= for transaction <- @transactions do %>
          <tr id={"transaction-#{transaction.id}"}>
            <td><%= transaction.amount %></td>
            <td><%= format_date(transaction.timestamp) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
