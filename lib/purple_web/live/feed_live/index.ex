defmodule PurpleWeb.FeedLive.Index do
  @moduledoc """
  RSS feed client
  """

  alias Purple.Feed
  import Purple.Filter
  use PurpleWeb, :live_view

  defp assign_data(socket) do
    filter = make_filter(socket.assigns.query_params)

    socket
    |> assign(:page_title, "Feed")
    |> assign(:filter, filter)
    |> assign(:items, Feed.list_items(filter))
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {
      :noreply,
      socket
      |> assign(:query_params, params)
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def handle_event("search", %{"filter" => filter_params}, socket) when is_map(filter_params) do
    {
      :noreply,
      push_patch(
        socket,
        to: ~p"/feed?#{filter_params}",
        replace: true
      )
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign(socket, :side_nav, nil)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>{@page_title}</h1>
    <.filter_form>
      <.page_links
        filter={@filter}
        first_page={~p"/feed?#{first_page(@filter)}"}
        next_page={~p"/feed?#{next_page(@filter)}"}
        num_rows={length(@items)}
      />
    </.filter_form>
    <div class="w-full overflow-auto">
      <.table rows={@items} get_route={fn filter -> ~p"/feed?#{filter}" end} filter={@filter}>
        <:col :let={item} label="Source">
          {item.source.title}
        </:col>
        <:col :let={item} label="Title">
          <.link href={item.link} target="_blank">{item.title}</.link>
        </:col>
        <:col :let={item} label="Published">
          {Purple.Date.format(item.pub_date, :time)}
        </:col>
      </.table>
      <.page_links
        filter={@filter}
        first_page={~p"/feed?#{first_page(@filter)}"}
        next_page={~p"/feed?#{next_page(@filter)}"}
        num_rows={length(@items)}
      />
    </div>
    """
  end
end
