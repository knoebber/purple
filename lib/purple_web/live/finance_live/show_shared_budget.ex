defmodule PurpleWeb.FinanceLive.ShowSharedBudget do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    info =
      id
      |> Finance.get_shared_budget_user_totals()
      |> Finance.process_shared_budget_user_totals()

    {
      :noreply,
      socket
      |> assign(:id, String.to_integer(id))
      |> assign(:max_cents, info.max_cents)
      |> assign(:page_title, "Shared Budget")
      |> assign(:users, info.users)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", params, socket) do
    Finance.delete_shared_budget!(socket.assigns.id)

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
    <%= if length(@users) == 0 do %>
      <button type="button" class="btn" phx-click="delete">Delete</button>
    <% end %>
    <ul>
      <%= for user <- @users do %>
        <li>
          <%= user.email %>: <%= format_cents(user.total_cents) %>
          <%= if user.total_cents < @max_cents do %>
            <span class="text-red-500">- <%= format_cents(user.cents_behind) %></span>
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end
end
