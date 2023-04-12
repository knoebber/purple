defmodule PurpleWeb.Components.SideNav do
  use PurpleWeb, :live_component
  alias PurpleWeb.FancyLink
  alias Purple.History

  @impl Phoenix.LiveComponent
  def update(%{side_nav: side_nav} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:side_nav, side_nav || [])
      |> assign(:should_hide, is_nil(side_nav))

    socket =
      case socket.assigns.current_user do
        nil ->
          assign(socket, :history, []) |> dbg

        user ->
          assign(
            socket,
            :history,
            History.list_user_viewed_urls(user.id)
            |> Enum.map(fn viewed_url_record ->
              FancyLink.build_route_tuple(viewed_url_record.url)
            end)
            |> Enum.map(fn {path, module, params} ->
              {path, FancyLink.get_fancy_link_title(module, params)}
            end)
          )
      end

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("global_navigate", %{"to" => to}, socket) do
    if socket.assigns.current_user do
      [url_without_params | _] = String.split(to, "?")
      {_, module, params} = FancyLink.build_route_tuple(url_without_params)

      if FancyLink.get_fancy_link_title(module, params) do
        History.save_url(socket.assigns.current_user.id, url_without_params)
      end
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <nav class={if @should_hide, do: "hidden"} phx-hook="SideNav" id="js-side-nav">
      <%= for link <- @side_nav do %>
        <.link navigate={link.to}><%= link.label %></.link>
        <div :if={Map.has_key?(link, :children) and length(link.children) > 0} class="side-link-group">
          <.link :for={child <- link.children} navigate={child.to}>
            <%= child.label %>
          </.link>
        </div>
      <% end %>
      <.link :for={{path, title} <- @history} navigate={path}><%= title %></.link>
    </nav>
    """
  end
end
