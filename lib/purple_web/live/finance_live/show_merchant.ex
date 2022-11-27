defmodule PurpleWeb.FinanceLive.ShowMerchant do
  alias Purple.Finance
  import PurpleWeb.FinanceLive.Helpers
  use PurpleWeb, :live_view

  defp assign_data(socket, merchant_id) do
    merchant = Finance.get_merchant!(merchant_id)

    socket
    |> assign(:page_title, merchant.name)
    |> assign(:merchant, merchant)
    |> assign_fancy_link_map(merchant.description)
  end

  defp apply_action(socket, :edit) do
    assign(socket, :is_editing, true)
  end

  defp apply_action(socket, :show) do
    assign(socket, :is_editing, false)
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    {
      :noreply,
      socket
      |> assign_data(id)
      |> apply_action(socket.assigns.live_action)
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:saved_merchant, merchant_id}, socket) do
    {
      :noreply,
      socket
      |> push_patch(to: ~p"/finance/merchants/#{merchant_id}", replace: true)
      |> put_flash(:info, "Merchant saved")
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>
    <.section class="mt-2 mb-2">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <.link :if={!@is_editing} patch={~p"/finance/merchants/#{@merchant.id}/edit"} replace={true}>
            Edit
          </.link>
          <.link :if={@is_editing} patch={~p"/finance/merchants/#{@merchant.id}"} replace={true}>
            Cancel
          </.link>
        </div>
        <.timestamp model={@merchant} />
      </div>
      <.live_component
        :if={@is_editing}
        action={:edit_merchant}
        class="p-4"
        current_user={@current_user}
        id={@merchant.id}
        module={PurpleWeb.FinanceLive.MerchantForm}
        merchant={@merchant}
      />
      <.markdown
        :if={!@is_editing}
        content={@merchant.description}
        link_type={:finance}
        fancy_link_map={@fancy_link_map}
      />
    </.section>
    """
  end
end
