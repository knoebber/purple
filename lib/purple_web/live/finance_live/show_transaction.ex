defmodule PurpleWeb.FinanceLive.ShowTransaction do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  defp assign_transaction(socket, transaction) do
    page_title =
      if transaction.description == "" do
        "Transaction #{transaction.id}"
      else
        transaction.description
      end

    socket
    |> assign(:page_title, page_title)
    |> assign(:transaction, transaction)
    |> assign(:is_editing, false)
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
    <h1><%= @page_title %></h1>
    <section class="mt-2 mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <%= if @is_editing do %>
            <%= link("Cancel",
              phx_click: "toggle_edit",
              to: "#"
            ) %>
          <% else %>
            <%= link("Edit",
              phx_click: "toggle_edit",
              to: "#"
            ) %>
          <% end %>
          <span>|</span>
          <%= link("Delete",
            phx_click: "delete",
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
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
        <div class="p-4">
          <p>
            <%= @transaction.merchant.name %> for <%= @transaction.dollars %> with <%= @transaction.payment_method.name %>
          </p>
        </div>
        <div class="markdown-content">
          <%= markdown(@transaction.notes, :finance) %>
        </div>
      <% end %>
    </section>
    """
  end
end
