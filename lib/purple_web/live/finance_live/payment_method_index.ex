defmodule PurpleWeb.FinanceLive.PaymentMethodIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.PaymentMethod

  @impl true
  def handle_info({:saved_payment_method, _id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Payment method saved")
      |> assign(:payment_methods, Finance.list_payment_methods(:transactions))
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Payment Methods")
      |> assign(:payment_methods, Finance.list_payment_methods(:transactions))
      |> assign(:side_nav, side_nav())
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
    <div class="mb-2 sm:w-1/3">
      <.live_component
        action={:new_payment_method}
        id={:new}
        module={PurpleWeb.FinanceLive.PaymentMethodForm}
        payment_method={%PaymentMethod{}}
      />
    </div>
    <.table rows={@payment_methods}>
      <:col let={payment_method} label="Name">
        <%= payment_method.name %>
      </:col>
      <:col let={payment_method} label="# Transactions">
        <%= length(payment_method.transactions) %>
      </:col>
    </.table>
    """
  end
end
