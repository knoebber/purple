defmodule PurpleWeb.Components.SideNav do
  use PurpleWeb, :live_component
  alias PurpleWeb.FancyLink
  alias Purple.History

  defp build_formatted_history(url_records) do
    FancyLink.build_fancy_link_groups(for r <- url_records, do: r.url)
  end

  defp get_history(nil) do
    nil
  end

  defp get_history(user) do
    case History.list_user_viewed_urls(user.id) do
      [] ->
        nil

      viewed_urls ->
        build_formatted_history(viewed_urls)
    end
  end

  @impl Phoenix.LiveComponent
  def update(%{side_nav: side_nav} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:side_nav, side_nav || [])
      |> assign(:history, get_history(assigns.current_user))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("global_navigate", %{"to" => to}, socket) do
    new_history =
      if socket.assigns.current_user do
        [url_without_params | _] = String.split(to, "?")

        title =
          url_without_params
          |> FancyLink.build_route_tuple()
          |> FancyLink.get_fancy_link_title()

        if title do
          socket.assigns.current_user.id
          |> History.save_url(url_without_params)
          |> build_formatted_history()
        end
      end

    {:noreply, assign(socket, :history, new_history || socket.assigns.history)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete_history", _, socket) do
    History.delete_history(socket.assigns.current_user.id)
    {:noreply, assign(socket, :history, nil)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <nav
      class={unless @side_nav, do: "hidden"}
      id="js-side-nav"
      phx-hook="SideNav"
      phx-target={@myself}
    >
      <%= for link <- @side_nav do %>
        <.link navigate={link.to}><%= link.label %></.link>
        <div :if={Map.has_key?(link, :children) and length(link.children) > 0} class="side-link-group">
          <.link :for={child <- link.children} navigate={child.to}>
            <%= child.label %>
          </.link>
        </div>
      <% end %>
      <%= if @history do %>
        <div class="history">
          <h4 class="history-header">History</h4>
          <div :for={{group_name, link_pairs} <- @history} class="history-group">
            <div class="side-link-group history">
              <span><%= group_name %></span>
              <.link :for={{path, title} <- link_pairs} navigate={path}><%= title %></.link>
            </div>
          </div>
        </div>
      <% end %>
    </nav>
    """
  end
end
