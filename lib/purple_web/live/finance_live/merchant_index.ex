defmodule PurpleWeb.FinanceLive.MerchantIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.Merchant

  @impl true
  def handle_info({:saved_merchant, _id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Merchant saved")
      |> assign(:merchants, Finance.list_merchants(:transactions))
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Merchants")
      |> assign(:merchants, Finance.list_merchants(:transactions))
      |> assign(:side_nav, side_nav())
    }
  end

  @impl Phoenix.LiveView
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <div class="mb-2 sm:w-1/3">
      <.live_component
        action={:new_merchant}
        id={:new}
        module={PurpleWeb.FinanceLive.MerchantForm}
        merchant={%Merchant{}}
      />
    </div>
    <.table rows={@merchants}>
      <:col :let={merchant} label="Name">
        <%= merchant.name %>
      </:col>
      <:col :let={merchant} label="Description">
        <%= merchant.description %>
      </:col>
      <:col :let={merchant} label="# Transactions">
        <%= length(merchant.transactions) %>
      </:col>
    </.table>
    """
  end
end
