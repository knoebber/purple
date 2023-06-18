defmodule PurpleWeb.FinanceLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Finance
  import Purple.Filter
  import PurpleWeb.FinanceLive.Helpers
  require Logger

  @filter_types %{
    category: :string,
    merchant_id: :integer,
    month: :string,
    payment_method_id: :integer
  }

  defp assign_data(socket) do
    user_id = socket.assigns.current_user.id

    filter =
      make_filter(
        socket.assigns.query_params,
        %{user_id: user_id},
        @filter_types
      )

    socket
    |> assign(:filter, filter)
    |> assign(:merchant_options, Finance.merchant_mappings(user_id))
    |> assign(:payment_method_options, Finance.payment_method_mappings(user_id))
    |> assign(:tag_options, Purple.Tags.make_tag_choices(:transaction, filter))
    |> assign(:transactions, Finance.list_transactions(filter))
  end

  defp apply_action(socket, :index, _) do
    assign(socket, :transaction_for_share, nil)
  end

  defp apply_action(socket, :share, %{"id" => transaction_id}) do
    shared_budgets = Finance.list_shared_budgets()

    if length(shared_budgets) == 1 do
      # N.B. this only works when there is a single shared budget for now.
      tx = Finance.get_transaction!(transaction_id, :shared_transaction)

      socket
      |> assign(:transaction_for_share, tx)
      |> assign(:shared_budget, hd(shared_budgets))
      |> assign(:transaction_is_shared, length(tx.shared_transaction) > 0)
    else
      apply_action(socket, :index, %{})
    end
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
      |> apply_action(socket.assigns.live_action, params)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/finance?#{params}", replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("import", _, socket) do
    user_id = socket.assigns.current_user.id
    result = Finance.import_transactions(user_id)

    socket =
      if result.failed > 0 do
        Enum.each(result.errors, fn error ->
          Logger.error("failed to import transaction for user #{user_id}: #{error}")
        end)

        put_flash(socket, :error, "Failed to import #{result.failed} transactions")
      else
        socket
      end

    socket =
      if result.success > 0 do
        put_flash(socket, :success, "Imported #{result.success} transactions")
      else
        socket
      end

    socket =
      if result.success == 0 and result.failed == 0 do
        put_flash(socket, :info, "All transactions are imported")
      else
        socket
      end

    {:noreply, assign_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "update_category",
        %{"transaction" => %{"id" => id} = params},
        socket
      ) do
    {:ok, transaction} = Finance.update_transaction(Finance.get_transaction!(id), params)
    transactions = socket.assigns.transactions
    tx_index = Enum.find_index(transactions, &(&1.id == transaction.id))
    old_transaction = Enum.at(transactions, tx_index)
    # Replace the transaction category from the socket's list. 
    # This preserves the preloaded data.
    # Don't reload whole list from database because that can cause the order to change.
    # TODO: use streams
    updated_transaction = Map.put(old_transaction, :category, transaction.category)

    {
      :noreply,
      socket
      |> assign(
        :transactions,
        List.replace_at(
          transactions,
          tx_index,
          updated_transaction
        )
      )
      |> put_flash(:info, "Updated category")
    }
  end

  @impl Phoenix.LiveView
  def handle_event("cycle_share", params, socket) do
    # N.B. this only works when there is a single shared budget for now.
    shared_budgets = Finance.list_shared_budgets()

    if length(shared_budgets) == 1 do
      transaction =
        Finance.get_transaction!(Purple.int_from_map(params, "id"), :shared_transaction)

      shared_budget = hd(shared_budgets)

      shared_transactions =
        case transaction.shared_transaction do
          [] ->
            {:ok, shared_transaction} =
              Finance.create_shared_transaction(
                shared_budget.id,
                %{transaction_id: transaction.id, type: :SHARE}
              )

            [shared_transaction]

          [%{type: :SHARE} = shared_transaction] ->
            {:ok, shared_transaction} =
              Finance.update_shared_transaction(shared_transaction, %{type: :CREDIT})

            [shared_transaction]

          [%{type: :CREDIT}] ->
            Finance.remove_shared_transaction!(
              shared_budget.id,
              transaction.id
            )

            []
        end

      transactions = socket.assigns.transactions
      tx_index = Enum.find_index(transactions, &(&1.id == transaction.id))
      old_transaction = Enum.at(transactions, tx_index)
      updated_transaction = Map.put(old_transaction, :shared_transaction, shared_transactions)

      {
        :noreply,
        assign(
          socket,
          :transactions,
          List.replace_at(
            transactions,
            tx_index,
            updated_transaction
          )
        )
      }
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1><%= @page_title %></h1>
    </div>
    <.modal
      :if={!!@transaction_for_share}
      id="share-transaction-modal"
      on_cancel={JS.patch(~p"/finance?#{@filter}", replace: true)}
      show
    >
      <:title>Share Transaction</:title>
      <.live_component
        id={@transaction_for_share.id}
        action={if @transaction_is_shared, do: :edit, else: :new}
        module={PurpleWeb.FinanceLive.SharedTransactionForm}
        shared_budget_id={@shared_budget.id}
        transaction={@transaction_for_share}
        shared_transaction={
          if @transaction_is_shared,
            do: hd(@transaction_for_share.shared_transaction),
            else: %Finance.SharedTransaction{}
        }
      />
      <%= if @transaction_is_shared do %>
        <.button phx-click="unshare_transaction" phx-value-id={@transaction_for_share.id}>
          Unshare
        </.button>
      <% end %>
    </.modal>
    <div class="flex flex-col md:flex-row gap-1 mb-2">
      <%= live_redirect(to: ~p"/finance/transactions/create") do %>
        <.button class="h-full" type="button">Create</.button>
      <% end %>
      <.form for={%{}} phx-submit="import">
        <.button
          class="pl-4 pr-4 text-lg bg-purple-200 border-collapse border-purple-400 border rounded h-full"
          phx-click="import"
          phx-disable-with="Importing..."
          title="Import transactions"
        >
          🏦
        </.button>
      </.form>
      <.filter_form :let={f}>
        <.input
          field={f[:query]}
          value={Map.get(@filter, :query, "")}
          placeholder="Search..."
          phx-debounce="200"
          class="lg:w-1/4"
        />
        <.input
          field={f[:tag]}
          type="select"
          options={@tag_options}
          value={Map.get(@filter, :tag, "")}
          class="lg:w-1/4"
        />
      </.filter_form>
    </div>
    <div class="w-full overflow-auto">
      <.table
        rows={@transactions}
        filter={@filter}
        get_route={fn filter -> ~p"/finance?#{filter}" end}
      >
        <:col :let={transaction} label="Amount" order_col="cents">
          <.link navigate={~p"/finance/transactions/#{transaction}"}>
            <%= transaction.dollars %>
          </.link>
        </:col>
        <:col :let={transaction} label="Merchant" order_col="merchant_id">
          <.link navigate={~p"/finance/merchants/#{transaction.merchant}"}>
            <%= transaction.merchant.name %>
          </.link>
        </:col>
        <:col :let={transaction} label="Payment Method" order_col="payment_method_id">
          <%= transaction.payment_method.name %>
        </:col>
        <:col :let={transaction} label="Category" order_col="category">
          <form phx-change="update_category" id={"transaction-#{transaction.id}-category"}>
            <input type="hidden" value={transaction.id} name="transaction[id]" />
            <select
              name="transaction[category]"
              class={[
                "text-xs py-2 px-3 pr-7 border border-gray-300",
                "bg-white rounded-md shadow-sm focus:outline-none",
                "focus:ring-zinc-500 focus:border-zinc-500"
              ]}
            >
              <%= Phoenix.HTML.Form.options_for_select(
                Finance.category_mappings(),
                transaction.category
              ) %>
            </select>
          </form>
        </:col>
        <:col :let={transaction} label="Description">
          <%= transaction.description %>
        </:col>
        <:col :let={transaction} label="Timestamp" order_col="timestamp">
          <%= Purple.Date.format(transaction.timestamp) %>
        </:col>
        <:col :let={transaction} label="Share">
          <.link href="#" phx-click="cycle_share" class="text-xl" phx-value-id={transaction.id}>
            <%= if length(transaction.shared_transaction) == 0 do %>
              🙈
            <% else %>
              <%= if hd(transaction.shared_transaction).type == :SHARE do %>
                🧍‍♀🧍
              <% else %>
                🦋
              <% end %>
            <% end %>
          </.link>
        </:col>
      </.table>
      <.page_links
        num_rows={length(@transactions)}
        filter={@filter}
        first_page={~p"/finance?#{first_page(@filter)}"}
        next_page={~p"/finance?#{next_page(@filter)}"}
      />
    </div>
    """
  end
end
