defmodule PurpleWeb.FinanceLive.ShowTransaction do
  use PurpleWeb, :live_view
  import PurpleWeb.FinanceLive.FinanceHelpers
  alias Purple.Finance

  @behaviour PurpleWeb.FancyLink

 defp assign_transaction(socket, transaction) do
    socket
    |> assign(:page_title, Finance.Transaction.to_string(transaction))
    |> assign(:transaction, transaction)
    |> assign(:is_editing, false)
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
    transaction = Finance.get_transaction!(id)

    {
      :noreply,
      assign_transaction(socket, transaction)
    }
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    Finance.delete_transaction!(socket.assigns.transaction)

    {
      :noreply,
      socket
      |> put_flash(:info, "Transaction deleted")
      |> push_redirect(to: index_path())
    }
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_edit", _, socket) do
    {:noreply, assign(socket, :is_editing, not socket.assigns.is_editing)}
  end

  @impl Phoenix.LiveView
  def handle_info({:saved, transaction}, socket) do
    {
      :noreply,
      socket
      |> assign_transaction(transaction)
      |> put_flash(:info, "Transaction saved")
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    <section class="mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1 mb-2">
        <div class="inline-links">
          <.link href="#" phx-click="toggle_edit">
            <%= if @is_editing do %>
              Cancel
            <% else %>
              Edit
            <% end %>
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
    </section>
    """
  end
end
