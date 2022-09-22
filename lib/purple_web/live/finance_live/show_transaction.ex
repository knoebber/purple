defmodule PurpleWeb.FinanceLive.ShowTransaction do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    transaction = Finance.get_transaction!(id)

    page_title =
      if transaction.description == "" do
        "Transaction #{transaction.id}"
      else
        transaction.description
      end

    {
      :noreply,
      socket
      |> assign(:transaction, transaction)
      |> assign(:page_title, page_title)
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
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>
    <section class="mt-2 mb-2 window">
      <div class="flex justify-between bg-purple-300 p-1">
        <div class="inline-links">
          <strong>
            Edit
          </strong>
          <span>|</span>
          <%= link("Delete",
            phx_click: "delete",
            data: [confirm: "Are you sure?"],
            to: "#"
          ) %>
        </div>
        <.timestamp model={@transaction} />
      </div>
      <div class="p-4">
        <p>
          <%= @transaction.merchant.name %> for <%= @transaction.dollars %> with
          <%= @transaction.payment_method.name %>
        </p>
      </div>
      <div class="markdown-content">
        <%= markdown(@transaction.notes, :finance) %>
      </div>
    </section>
    """
  end
end
