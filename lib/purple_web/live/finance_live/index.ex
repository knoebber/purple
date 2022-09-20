defmodule PurpleWeb.FinanceLive.Index do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers
  import Purple.Filter2

  alias Purple.Finance

  @filter_types %{
    merchant_id: :integer,
    payment_method_id: :integer
  }

  defp assign_data(socket) do
    filter =
      make_filter(
        socket.assigns.query_params,
        %{user_id: socket.assigns.current_user.id},
        @filter_types
      )

    socket
    |> assign(:filter, filter)
    |> assign(:merchant_options, Finance.merchant_mappings())
    |> assign(:payment_method_options, Finance.payment_method_mappings())
    |> assign(:tag_options, Purple.Tags.make_tag_choices(:transaction, filter))
    |> assign(:transactions, Finance.list_transactions(filter))
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:side_nav, side_nav())
      |> assign(:page_title, "Transactions")
    }
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => params}, socket) do
    {:noreply, push_patch(socket, to: index_path(params), replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("import", _, socket) do
    Finance.import_transactions(socket.assigns.current_user.id)

    {
      :noreply,
      assign_data(socket)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Finance.get_transaction!()
    |> Finance.delete_transaction!()

    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1><%= @page_title %></h1>
    </div>
    <.form
      class="table-filters"
      for={:filter}
      let={f}
      method="get"
      phx-change="search"
      phx-submit="search"
    >
      <button
        type="btn"
        class="window pl-4 pr-4 text-lg"
        phx-click="import"
        title="Import transactions"
      >
        🏦
      </button>
      <%= text_input(
        f,
        :query,
        value: Map.get(@filter, :query, ""),
        placeholder: "Search...",
        phx_debounce: "200",
        class: "lg:w-1/4"
      ) %>
      <%= select(
        f,
        :tag,
        @tag_options,
        value: Map.get(@filter, :tag, ""),
        class: "lg:w-1/4"
      ) %>
      <%= select(
        f,
        :merchant_id,
        [[value: "", key: "🧟‍♀️ All merchants"]] ++ @merchant_options,
        value: Map.get(@filter, :merchant_id, "")
      ) %>
      <%= select(
        f,
        :payment_method_id,
        [[value: "", key: "💸 All payment methods"]] ++ @payment_method_options,
        value: Map.get(@filter, :payment_method_id, "")
      ) %>
    </.form>
    <div class="w-full overflow-auto">
      <.table rows={@transactions}>
        <:col let={transaction} label="Amount">
          <%= live_redirect(transaction.dollars, to: show_transaction_path(transaction)) %>
        </:col>
        <:col let={transaction} label="Date">
          <.timestamp model={transaction} . />
        </:col>
        <:col let={transaction} label="Merchant">
          <%= transaction.merchant.name %>
        </:col>
        <:col let={transaction} label="Payment Method">
          <%= transaction.payment_method.name %>
        </:col>
        <:col let={transaction} label="Description">
          <%= transaction.description %>
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
    </div>
    """
  end
end
