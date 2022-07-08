defmodule PurpleWeb.FinanceLive.ShowSharedBudget do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp assign_data(socket, shared_budget_id) do
    info =
      shared_budget_id
      |> Finance.get_shared_budget_user_totals()
      |> Finance.process_shared_budget_user_totals()

    user_transactions =
      Finance.list_transactions(%{
        not_shared_budget_id: shared_budget_id,
        user_id: socket.assigns.current_user.id
      })

    shared_budget = Finance.get_shared_budget(shared_budget_id)

    socket =
      socket
      |> assign(:adjustment, %Finance.SharedBudgetAdjustment{})
      |> assign(:max_cents, info.max_cents)
      |> assign(:page_title, "Shared Budget")
      |> assign(:shared_budget, shared_budget)
      |> assign(:shared_budget_id, shared_budget_id)
      |> assign(:user_transactions, user_transactions)
      |> assign(:users, info.users)

    if shared_budget.show_adjustments do
      assign(socket, :adjustments, Finance.list_shared_budget_adjustments(shared_budget_id))
    else
      socket
    end
  end

  defp get_map_int(params, key) do
    case Integer.parse(Map.get(params, key)) do
      {0, _} -> nil
      {id, ""} -> id
      _ -> nil
    end
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    shared_budget_id = String.to_integer(id)

    {
      :noreply,
      socket
      |> assign_data(shared_budget_id)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_show_adjustments", _, socket) do
    sb = socket.assigns.shared_budget
    Finance.toggle_show_adjustments(sb.id, !sb.show_adjustments)
    {:noreply, assign_data(socket, sb.id)}
  end

  @impl Phoenix.LiveView
  def handle_event("share_transaction", params, socket) do
    shared_budget_id = socket.assigns.shared_budget_id

    transaction_id = get_map_int(params, "transaction_id")

    if transaction_id do
      Finance.create_shared_transaction!(shared_budget_id, transaction_id)

      {:noreply, assign_data(socket, shared_budget_id)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("remove_transaction", params, socket) do
    shared_budget_id = socket.assigns.shared_budget_id

    Finance.remove_shared_transaction!(shared_budget_id, get_map_int(params, "id"))

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
      id: get_map_int(params, "id")
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
    Finance.delete_shared_budget!(socket.assigns.shared_budget_id)

    {
      :noreply,
      socket
      |> put_flash(:info, "Deleted shared budget")
      |> push_redirect(to: shared_budget_index_path())
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <%= if @live_action in [:edit_adjustment, :new_adjustment] do %>
      <.modal
        title="Adjust Shared Budget"
        return_to={show_shared_budget_path(@shared_budget_id, :show)}
      >
        <.live_component
          action={@live_action}
          adjustment={@adjustment}
          current_user={@current_user}
          id={@adjustment.id || :new}
          module={PurpleWeb.FinanceLive.SharedBudgetAdjustmentForm}
          params={%{}}
          shared_budget_id={@shared_budget_id}
        />
      </.modal>
    <% end %>
    <%= if length(@users) == 0 do %>
      <button type="button" class="btn mb-2" phx-click="delete">Delete</button>
    <% end %>
    <form class="flex flex-row mb-2" phx-submit="share_transaction">
      <select name="transaction_id">
        <option value="0"><%= @current_user.email %>'s transactions</option>
        <%= for tx <- @user_transactions do %>
          <option value={tx.id}>
            <%= tx.dollars %> on <%= format_date(tx.timestamp) %> for <%= tx.merchant.name %> with
            <%= tx.payment_method.name %>
          </option>
        <% end %>
      </select>
      <button class="ml-3" type="submit">Add</button>
    </form>
    <div>
      <div class="flex p-1 mb-2 items-center">
        <%= link(if(@shared_budget.show_adjustments, do: "[-]", else: "[+]"),
          phx_click: "toggle_show_adjustments",
          to: "#",
          class: "no-underline font-mono"
        ) %>
        <h2>Adjustments</h2>
      </div>
      <%= if @shared_budget.show_adjustments do %>
        <%= live_patch(to: show_shared_budget_path(@shared_budget_id, :new_adjustment)) do %>
          <button class="btn mb-2">Add</button>
        <% end %>
        <div>
          <%= for user <- @users do %>
            <strong>
              <%= user.email %>: <%= format_cents(user.adjustment_cents) %>
            </strong>
          <% end %>
        </div>
        <.table rows={@adjustments}>
          <:col let={a} label="User">
            <%= a.user.email %>
          </:col>
          <:col let={a} label="Amount">
            <%= a.dollars %>
          </:col>
          <:col let={a} label="Description">
            <%= a.description %>
          </:col>
          <:col let={a} label="">
            <%= link("Delete",
              phx_click: "delete_adjustment",
              phx_value_id: a.id,
              to: "#"
            ) %>
          </:col>
        </.table>
      <% end %>
    </div>
    <div class="flex flex-col md:flex-row">
      <%= for user <- @users do %>
        <div class="flex flex-col p-1">
          <h2>
            <%= user.email %>: <%= format_cents(user.total_cents) %>
            <%= if user.total_cents < @max_cents do %>
              <span class="text-red-500">- <%= format_cents(user.cents_behind) %></span>
            <% end %>
          </h2>
          <.table rows={user.transactions}>
            <:col let={transaction} label="Amount">
              <%= transaction.dollars %>
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
              <%= link("Remove",
                phx_click: "remove_transaction",
                phx_value_id: transaction.id,
                to: "#"
              ) %>
            </:col>
          </.table>
        </div>
      <% end %>
    </div>
    """
  end
end
