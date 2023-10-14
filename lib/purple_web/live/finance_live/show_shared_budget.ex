defmodule PurpleWeb.FinanceLive.ShowSharedBudget do
  use PurpleWeb, :live_view
  import PurpleWeb.FinanceLive.Helpers
  alias Purple.Finance

  @behaviour PurpleWeb.FancyLink

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🧍‍💵🧍"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(params) do
    case params do
      %{"adjustment_id" => id} ->
        adjustment = Finance.get_shared_budget_adjustment(id)

        if adjustment do
          adjustment.dollars <> " adjustment"
        end

      %{"id" => id} ->
        shared_budget = Finance.get_shared_budget(id)

        if shared_budget do
          shared_budget.name
        end
    end
  end

  defp map_user_transactions(user_id, shared_budget_id) do
    Enum.map(
      Finance.list_transactions(%{
        not_shared_budget_id: shared_budget_id,
        user_id: user_id
      }),
      fn tx ->
        [value: tx.id, key: Finance.Transaction.to_string(tx)]
      end
    )
  end

  defp assign_data(socket, shared_budget_id, adjustment_id \\ nil) do
    user_data =
      shared_budget_id
      |> Finance.get_shared_budget_user_totals()
      |> Finance.make_shared_budget_user_data()

    user_transactions = shared_budget = Finance.get_shared_budget(shared_budget_id)

    adjustment =
      if adjustment_id do
        Finance.get_shared_budget_adjustment!(adjustment_id)
      else
        %Finance.SharedBudgetAdjustment{user_id: socket.assigns.current_user.id}
      end

    socket
    |> assign(:adjustment, adjustment)
    |> assign(:max_balance_cents, user_data.max_balance_cents)
    |> assign(:page_title, shared_budget.name)
    |> assign(:shared_budget, shared_budget)
    |> assign(:user_transactions, user_transactions)
    |> assign(:users, user_data.users)
    |> assign(:user_mappings, user_data.user_mappings)
    |> assign(
      :user_transaction_mappings,
      map_user_transactions(socket.assigns.current_user.id, shared_budget_id)
    )
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {
      :noreply,
      socket
      |> assign_data(
        Purple.int_from_map(params, "id"),
        Purple.int_from_map(params, "adjustment_id")
      )
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_show_adjustments", _, socket) do
    sb = socket.assigns.shared_budget
    Finance.toggle_show_adjustments(sb.id, !sb.show_adjustments)
    {:noreply, assign_data(socket, sb.id)}
  end

  @impl Phoenix.LiveView
  def handle_event("remove_transaction", params, socket) do
    shared_budget_id = socket.assigns.shared_budget.id

    Finance.remove_shared_transaction!(shared_budget_id, Purple.int_from_map(params, "id"))

    {
      :noreply,
      socket
      |> put_flash(:info, "Removed transaction")
      |> assign_data(shared_budget_id)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete_adjustment", params, socket) do
    Finance.delete_shared_budget_adjustment(%Finance.SharedBudgetAdjustment{
      id: Purple.int_from_map!(params, "id")
    })

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted adjustment")
      |> assign_data(socket.assigns.shared_budget.id)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    Finance.delete_shared_budget!(socket.assigns.shared_budget.id)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted shared budget")
      |> push_redirect(to: ~p"/finance/shared_budgets", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.modal
      :if={@live_action in [:edit_adjustment, :new_adjustment, :show_adjustment]}
      id="adjust-shared-budget-modal"
      on_cancel={JS.patch(~p"/finance/shared_budgets/#{@shared_budget}", replace: true)}
      show
    >
      <:title>
        Shared Budget Adjustment
      </:title>
      <%= if @live_action == :show_adjustment do %>
        <.live_component
          adjustment={@adjustment}
          shared_budget={@shared_budget}
          id="show-adjustment-modal"
          module={PurpleWeb.FinanceLive.ShowSharedBudgetAdjustment}
        />
      <% else %>
        <.live_component
          action={@live_action}
          adjustment={@adjustment}
          current_user={@current_user}
          id={@adjustment.id || :new}
          module={PurpleWeb.FinanceLive.SharedBudgetAdjustmentForm}
          params={%{}}
          shared_budget_id={@shared_budget.id}
          user_mappings={@user_mappings}
        />
      <% end %>
    </.modal>
    <.button :if={length(@users) == 0} class="mb-2" phx-click="delete">Delete</.button>
    <div class="p-1 mb-2 flex">
      <.link href="#" phx-click="toggle_show_adjustments" class="font-mono">
        <%= if(@shared_budget.show_adjustments, do: "Hide Adjustments", else: "Show Adjustments") %>
      </.link>
    </div>
    <%= if @shared_budget.show_adjustments do %>
      <.link patch={~p"/finance/shared_budgets/#{@shared_budget}/adjustments/new"} replace={true}>
        <.button class="mb-2">New Adjustment</.button>
      </.link>
    <% end %>
    <div class="grid grid-cols-1 md:grid-cols-2 w-full overflow-auto">
      <%= for user <- @users do %>
        <h2>
          <%= user.email %>
          <%= if user.balance_cents < @max_balance_cents do %>
            <span class="text-red-500">
              - <%= Finance.Transaction.format_cents(@max_balance_cents - user.balance_cents) %>
            </span>
          <% end %>
        </h2>
      <% end %>
      <%= if @shared_budget.show_adjustments do %>
        <%= for user <- @users do %>
          <div class="p-1">
            <.table rows={user.adjustments}>
              <:col :let={row} label="Amount">
                <.link
                  patch={~p"/finance/shared_budgets/#{@shared_budget}/adjustments/#{row}"}
                  replace={true}
                >
                  <%= row.dollars %>
                </.link>
              </:col>
              <:col :let={row} label="Type">
                <%= row.type %>
              </:col>
              <:col :let={row} label="Description">
                <%= row.description %>
              </:col>
              <:col :let={row} label="">
                <.link href="#" phx-click="delete_adjustment" phx-value-id={row.id}>
                  ❌
                </.link>
              </:col>
            </.table>
          </div>
        <% end %>
      <% end %>
      <%= for user <- @users do %>
        <div class="p-1">
          <.table rows={user.transactions}>
            <:col :let={transaction} label="Transaction">
              <.link navigate={~p"/finance/transactions/#{transaction}"}>
                <%= Finance.Transaction.to_string(transaction) %>
              </.link>
            </:col>
            <:col :let={transaction} label="Type">
              <%= hd(transaction.shared_transaction).type %>
            </:col>
            <:col :let={transaction} label="">
              <.link href="#" phx-click="remove_transaction" phx-value-id={transaction.id}>
                ❌
              </.link>
            </:col>
          </.table>
        </div>
      <% end %>
    </div>
    """
  end
end
