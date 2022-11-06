defmodule PurpleWeb.FinanceLive.ShowMerchant do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp assign_merchant(socket, merchant) do
    socket
    |> assign(:page_title, merchant.name)
    |> assign(:merchant, merchant)
    |> assign(:is_editing, false)
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    merchant = Finance.get_merchant!(id)

    {
      :noreply,
      assign_merchant(socket, merchant)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_edit", _, socket) do
    {:noreply, assign(socket, :is_editing, not socket.assigns.is_editing)}
  end

  @impl Phoenix.LiveView
  def handle_info({:saved_merchant, merchant_id}, socket) do
    {
      :noreply,
      socket
      |> assign_merchant(Finance.get_merchant!(merchant_id))
      |> put_flash(:info, "Merchant saved")
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>
    <section class="mt-2 mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <.link href="#" phx-click="toggle_edit">
            <%= if @is_editing do %>
              Cancel
            <% else %>
              Edit
            <% end %>
          </.link>
        </div>
        <.timestamp model={@merchant} />
      </div>
      <%= if @is_editing do %>
        <.live_component
          action={:edit_merchant}
          class="p-4"
          current_user={@current_user}
          id={@merchant.id}
          module={PurpleWeb.FinanceLive.MerchantForm}
          merchant={@merchant}
        />
      <% else %>
        <div class="markdown-content">
          <%= markdown(@merchant.description, link_type: :finance) %>
        </div>
      <% end %>
    </section>
    """
  end
end
