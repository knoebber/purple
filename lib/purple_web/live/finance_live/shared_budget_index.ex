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
  def handle_event("change_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :name, name)}
  end

  @impl Phoenix.LiveView
  def handle_event("new", _, socket) do
    Finance.create_shared_budget!(socket.assigns.name)

    {
      :noreply,
      assign(socket, :shared_budgets, Finance.list_shared_budgets())
    }
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :name, "")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">Add Shared Budgets</h1>
    <form phx-submit="new" class="sm:w-1/3">
      <div class="flex flex-col mb-2">
        <input type="text" name="name" phx-change="change_name" value={@name} />
      </div>
      <button class="btn mb-2" type="button" phx-click="new">
        Save
      </button>
    </form>
    <ul>
      <%= for shared_budget <- @shared_budgets do %>
        <li>
          <%= live_redirect(shared_budget_title(shared_budget),
            to: Routes.finance_show_shared_budget_path(@socket, :show, shared_budget)
          ) %>
        </li>
      <% end %>
    </ul>
    """
  end
end
