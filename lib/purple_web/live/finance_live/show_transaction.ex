defmodule PurpleWeb.FinanceLive.ShowTransaction do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.FinanceHelpers

  alias Purple.Finance
  alias PurpleWeb.Markdown

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, side_nav())}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    transaction = Finance.get_transaction!(id)

    page_title = "Transaction #{transaction.id}"

    {
      :noreply,
      socket
      |> assign(:transaction, transaction)
      |> assign(:page_title, page_title)
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1><%= @page_title %></h1>
    <section class="mt-2 mb-2 window">
      <h2>
        <%= Markdown.markdown_to_html("# #{@transaction.description}", :finance) %>
      </h2>
      <div class="p-4">
        <%= @transaction.merchant.name %>
        <br />
        <%= @transaction.payment_method.name %>
        <br />
        <%= @transaction.dollars %>
        <br />
        <.timestamp model={@transaction} />
      </div>
      <div class="markdown-content">
        <%= Markdown.markdown_to_html(@transaction.notes, :finance) %>
      </div>
    </section>
    """
  end
end
