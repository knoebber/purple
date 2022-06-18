defmodule PurpleWeb.FinanceLive.Shared do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {
      :noreply,
      socket
    }
  end

  @impl Phoenix.LiveView
  def handle_event(event, params, socket) do
    IO.inspect(event, label: "implement me")
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex mb-2">
      <h1>Shared</h1>
      <%= live_patch(
        to: shared_path(),
        class: "text-xl self-end ml-1")
      do %>
        <button>➕</button>
      <% end %>
    </div>
    """
  end
end
