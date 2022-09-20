defmodule PurpleWeb.FinanceLive.CreateTransaction do
  @moduledoc """
  Page for creating transactions
  """

  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:side_nav, side_nav())
      |> assign(:page_title, "Create Transaction")
    }
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.live_component
        id={:new}
        module={PurpleWeb.FinanceLive.TransactionForm}
        transaction={%Transaction{}}
        action={:new_transaction}
    />
    """
  end
end
