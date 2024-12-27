defmodule PurpleWeb.FinanceLive.MerchantIndex do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.Helpers

  alias Purple.Finance

  defp assign_data(socket) do
    socket
    |> assign(:merchants, Finance.list_merchants(socket.assigns.current_user.id))
    |> assign(:filtered_merchants, nil)
    |> assign(:q, "")
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
  def handle_event("search", %{"q" => q}, socket) do
    socket =
      if q == "" do
        assign(socket, :filtered_merchants, nil)
      else
        assign(
          socket,
          :filtered_merchants,
          Enum.filter(
            socket.assigns.merchants,
            &String.contains?(String.downcase(&1.primary_name), String.downcase(q))
          )
        )
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("new_merchant", %{"name" => name}, socket) do
    mn = Finance.get_or_create_merchant!(name)
    {:noreply, push_navigate(socket, to: ~p"/finance/merchants/#{mn.merchant_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.flex_col>
      <h1>{@page_title}</h1>
      <div class="flex gap-8">
        <form class="w-96" phx-change="search">
          <.input name="q" value={@q} label="Search" />
        </form>
        <form class="w-96" phx-submit="new_merchant">
          <.input name="name" value={@q} label="Get or create merchant" />
        </form>
      </div>
      <div class="flex flex-wrap gap-5 ">
        <div
          :for={merchant <- @filtered_merchants || @merchants}
          class="p-4 bg-purple-100 border-collapse border-purple-400 border rounded"
        >
          <.link navigate={~p"/finance/merchants/#{merchant}"}>
            {merchant.primary_name}
          </.link>
        </div>
      </div>
    </.flex_col>
    """
  end
end
