defmodule PurpleWeb.FinanceLive.CreateTransaction do
  @moduledoc """
  Page for creating transactions
  """

  use PurpleWeb, :live_view
  import PurpleWeb.FinanceLive.FinanceHelpers
  alias Purple.Finance.Transaction

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
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:redirect, transaction}, socket) do
    {:noreply, push_redirect(socket, to: show_transaction_path(transaction))}
  end

  def handle_info({:saved, _}, socket) do
    {:noreply, put_flash(socket, :info, "Transaction saved")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <.live_component
      action={:new_transaction}
      class="xl:w-2/3"
      current_user={@current_user}
      id={:new}
      module={PurpleWeb.FinanceLive.TransactionForm}
      transaction={%Transaction{}}
    />
    """
  end
end
