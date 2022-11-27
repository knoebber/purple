defmodule PurpleWeb.FinanceLive.Index do
  use PurpleWeb, :live_view

  alias Purple.Finance
  import Purple.Filter
  import PurpleWeb.FinanceLive.Helpers
  require Logger

  @filter_types %{
    merchant_id: :integer,
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
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1><%= @page_title %></h1>
    </div>
    <div class="flex flex-col md:flex-row gap-1 mb-2">
      <%= live_redirect(to: ~p"/finance/transactions/create") do %>
        <.button class="h-full" type="button">Create</.button>
      <% end %>
      <.form for={:import} phx-submit="import">
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
          field={{f, :query}}
          value={Map.get(@filter, :query, "")}
          placeholder="Search..."
          phx-debounce="200"
          class="lg:w-1/4"
        />
        <.input
          field={{f, :tag}}
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
          <%= live_redirect(transaction.dollars, to: ~p"/finance/transactions/#{transaction}") %>
        </:col>
        <:col :let={transaction} label="Timestamp" order_col="timestamp">
          <%= Purple.Date.format(transaction.timestamp) %>
        </:col>
        <:col :let={transaction} label="Merchant">
          <%= transaction.merchant.name %>
        </:col>
        <:col :let={transaction} label="Payment Method">
          <%= transaction.payment_method.name %>
        </:col>
        <:col :let={transaction} label="Description">
          <%= transaction.description %>
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
