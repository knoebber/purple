defmodule PurpleWeb.FinanceLive.MerchantIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.Merchant

  defp assign_data(socket) do
    assign(
      socket,
      :merchants,
      Finance.list_merchants(socket.assigns.current_user.id)
    )
  end

  @impl true
  def handle_info({:saved_merchant, _id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Merchant saved")
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Merchants")
      |> assign(:side_nav, side_nav())
      |> assign_data
    }
  end

  @impl Phoenix.LiveView
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Finance.get_merchant!()
    |> Finance.delete_merchant!()

    {:noreply, assign_data(socket)}
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
      <:col :let={row} label="Name">
        <%= row.name %>
      </:col>
      <:col :let={row} label="Description">
        <%= row.description %>
      </:col>
      <:col :let={row} label="# Transactions">
        <%= if length(row.transactions) > 0 do %>
          <.link navigate={index_path(%{merchant_id: row.id})}>
            <%= length(row.transactions) %>
          </.link>
        <% else %>
          0
        <% end %>
      </:col>
      <:col :let={row} label="">
        <%= if length(row.transactions) == 0 do %>
          <.link href="#" phx-click="delete" phx-value-id={row.id}>
            Delete
          </.link>
        <% end %>
      </:col>
    </.table>
    """
  end
end
