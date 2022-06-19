defmodule PurpleWeb.FinanceLive.SharedBudgetIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Shared Budgets")
      |> assign(:shared_budgets, Finance.list_shared_budgets())
      |> assign(:side_nav, side_nav())
    }
  end

  @impl Phoenix.LiveView
  def handle_event("new", params, socket) do
    Finance.create_shared_budget!()

    {
      :noreply,
      assign(socket, :shared_budgets, Finance.list_shared_budgets())
    }
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">Shared Budgets</h1>
    <button class="btn mb-2" type="button" phx-click="new">
      New Shared Budget
    </button>
    <ul>
      <%= for shared_budget <- @shared_budgets do %>
        <li>
          <%= live_redirect(shared_budget.id,
            to: Routes.finance_show_shared_budget_path(@socket, :show, shared_budget)
          ) %>
        </li>
      <% end %>
    </ul>
    """
  end
end
