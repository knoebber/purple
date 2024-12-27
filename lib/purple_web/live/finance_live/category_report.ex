defmodule PurpleWeb.FinanceLive.CategoryReport do
  use PurpleWeb, :live_view

  import PurpleWeb.FinanceLive.Helpers

  alias Purple.Finance

  defp parse_month(month_string) do
    [year, month] = String.split(month_string, "-")
    Date.new!(Purple.parse_int!(year), Purple.parse_int!(month), 1)
  end

  defp assign_data(socket) do
    assign(
      socket,
      :report,
      Finance.sum_transactions_by_category(%{user_id: socket.assigns.current_user.id})
    )
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Categories")
      |> assign(:side_nav, side_nav())
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2">{@page_title}</h1>
    <.table rows={@report}>
      <:col :let={row} label="Category">
        <.link navigate={~p"/finance?category=#{row.category}"}>
          {Purple.titleize(row.category)}
        </.link>
      </:col>
      <:col :let={row} label="Month">
        <.link navigate={~p"/finance?month=#{row.month}"}>
          {Purple.Date.format(parse_month(row.month), :month)}
        </.link>
      </:col>
      <:col :let={row} label="Total">
        <.link navigate={~p"/finance?category=#{row.category}&month=#{row.month}"}>
          {Finance.Transaction.format_cents(row.cents)}
        </.link>
      </:col>
    </.table>
    """
  end
end
