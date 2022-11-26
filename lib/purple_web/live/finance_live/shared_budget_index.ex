defmodule PurpleWeb.FinanceLive.SharedBudgetIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.Helpers

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
        <.input
          errors={[]}
          id="shared-budget-name"
          label="New Shared Budget"
          name="name"
          phx-change="change_name"
          value={@name}
        />
      </div>
      <.button class="mb-2" phx-disable-with="Saving">
        Save
      </.button>
    </form>
    <ul>
      <li :for={shared_budget <- @shared_budgets}>
        <.link navigate={~p"/finance/shared_budgets/#{shared_budget}"}>
          <%= shared_budget.name %>
        </.link>
      </li>
    </ul>
    """
  end
end
