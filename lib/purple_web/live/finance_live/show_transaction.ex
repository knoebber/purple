defmodule PurpleWeb.FinanceLive.ShowTransaction do
  alias Purple.Finance
  import PurpleWeb.FinanceLive.Helpers
  use PurpleWeb, :live_view

  @behaviour PurpleWeb.FancyLink

  defp assign_data(socket, transaction_id) do
    transaction = Finance.get_transaction!(transaction_id)

    socket
    |> assign(:transaction, transaction)
    |> assign(:page_title, Finance.Transaction.to_string(transaction))
  end

  defp apply_action(socket, :edit) do
    assign(socket, :is_editing, true)
  end

  defp apply_action(socket, :show) do
    assign(socket, :is_editing, false)
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_type do
    "Transaction"
  end

  @impl PurpleWeb.FancyLink
  def get_fancy_link_title(%{"id" => tx_id}) do
    transaction = Finance.get_transaction(tx_id)

    if transaction do
      Finance.Transaction.to_string(transaction)
    end
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
    Finance.delete_transaction!(socket.assigns.transaction)

    {
      :noreply,
      socket
      |> put_flash(:info, "Transaction deleted")
      |> push_redirect(to: ~p"/finance", replace: true)
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:saved, _}, socket) do
    {
      :noreply,
      socket
      |> push_patch(to: ~p"/finance/transactions/#{socket.assigns.transaction}", replace: true)
      |> put_flash(:info, "Transaction saved")
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">
      <%= @page_title %>
    </h1>
    <.section class="mb-2">
      <div class="flex justify-between bg-purple-300 p-1 mb-2">
        <div class="inline-links">
          <.link
            :if={!@is_editing}
            patch={~p"/finance/transactions/#{@transaction}/edit"}
            replace={true}
          >
            Edit
          </.link>
          <.link :if={@is_editing} patch={~p"/finance/transactions/#{@transaction}"} replace={true}>
            Cancel
          </.link>
          <span>|</span>
          <.link href="#" phx-click="delete" data-confirm="Are you sure?">
            Delete
          </.link>
        </div>
        <.timestamp model={@transaction} />
      </div>
      <%= if @is_editing do %>
        <.live_component
          action={:edit_transaction}
          class="p-4"
          current_user={@current_user}
          id={@transaction.id}
          module={PurpleWeb.FinanceLive.TransactionForm}
          transaction={@transaction}
        />
      <% else %>
        <div class="pl-4">
          <p>Paid with: <%= @transaction.payment_method.name %></p>
          <p :if={@transaction.description != ""}>
            Description: <%= @transaction.description %>
          </p>
          <p :if={@transaction.notes != ""}>
            Notes 👇
          </p>
        </div>
        <div class="markdown-content mt-2">
          <%= markdown(@transaction.notes, link_type: :finance) %>
        </div>
      <% end %>
    </.section>
    """
  end
end
