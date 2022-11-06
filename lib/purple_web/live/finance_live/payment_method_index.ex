defmodule PurpleWeb.FinanceLive.PaymentMethodIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.PaymentMethod

  defp assign_data(socket) do
    assign(
      socket,
      :payment_methods,
      Finance.list_payment_methods(socket.assigns.current_user.id)
    )
  end

  @impl true
  def handle_info({:saved_payment_method, _id}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "Payment method saved")
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Payment Methods")
      |> assign(:side_nav, side_nav())
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    id
    |> Finance.get_payment_method!()
    |> Finance.delete_payment_method!()

    {:noreply, assign_data(socket)}
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
      <:col :let={row} label="Name">
        <%= row.name %>
      </:col>
      <:col :let={row} label="# Transactions">
        <%= if length(row.transactions) > 0 do %>
          <.link navigate={index_path(%{payment_method_id: row.id})}>
            <%= length(row.transactions) %>
          </.link>
        <% else %>
          0
        <% end %>
      </:col>
      <:col :let={row} label="">
        <%= if length(row.transactions) == 0 do %>
          <.link href="#" phx-click="delete" phx-value-id={row.id}>
            ❌
          </.link>
        <% end %>
      </:col>
    </.table>
    """
  end
end
