defmodule PurpleWeb.FinanceLive.ShowMerchant do
  alias Purple.Finance
  alias Purple.Finance.{Transaction}
  import PurpleWeb.FinanceLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "🧟‍♀️"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => merchant_id}) do
    merchant = Finance.get_merchant(merchant_id)

    if merchant do
      merchant.primary_name
    end
  end

  defp assign_data(socket, merchant_id) do
    merchant = Finance.get_merchant!(merchant_id)

    transactions =
      Finance.list_transactions(%{
        merchant_id: merchant_id,
        user_id: socket.assigns.current_user.id
      })

    socket
    |> assign(:page_title, merchant.primary_name)
    |> assign(:merchant, merchant)
    |> assign(:transactions, transactions)
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
  def handle_event("delete", _, socket) do
    Finance.delete_merchant!(socket.assigns.merchant)

    {
      :noreply,
      socket
      |> put_flash(:info, "deleted merchant '#{socket.assigns.merchant.primary_name}'")
      |> push_navigate(to: ~p"/finance/merchants")
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

  defp transactions_string(transactions) do
    n = length(transactions)
    result = "#{n} transaction"
    if n > 1, do: "#{result}s", else: result
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
          <.link :if={@transactions == []} href="#" phx-click="delete">Delete</.link>
          <.link :if={@is_editing} patch={~p"/finance/merchants/#{@merchant.id}"} replace={true}>
            Cancel
          </.link>
          <.link :if={length(@transactions) > 0} navigate={~p"/finance?merchant_id=#{@merchant.id}"}>
            <%= transactions_string(@transactions) %>
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
        <.flex_col>
          <div :if={length(@merchant.names) > 1} class="flex gap-3">
            <span class="p-1">🧟‍♀️ Names:</span>
            <span
              :for={name <- @merchant.names}
              :if={not name.is_primary}
              class="p-1 bg-purple-100 border-collapse border-purple-400 border rounded"
            >
              <span>‍️<%= name.name %></span>
            </span>
          </div>
          <div :if={!@is_editing}>
            Category: <%= Purple.titleize(@merchant.category) %>
          </div>
          Transactions <%= PurpleWeb.FinanceLive.ShowTransaction.get_fancy_link_type() %>
          <div :for={tx <- @transactions}>
            <.link navigate={~p"/finance/transactions/#{tx}"}>
              <%= Transaction.to_string(tx) %>
            </.link>
          </div>
        </.flex_col>
        <.markdown
          content={@merchant.description}
          link_type={:finance}
          fancy_link_map={@fancy_link_map}
        />
      <% end %>
    </.section>
    """
  end
end
