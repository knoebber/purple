defmodule PurpleWeb.Components.SideNav do
  use PurpleWeb, :live_component
  alias PurpleWeb.FancyLink
  alias Purple.History

  defp build_formatted_history(viewed_urls) do
    viewed_urls
    |> Enum.map(fn viewed_url_record ->
      FancyLink.build_route_tuple(viewed_url_record.url)
    end)
    |> Enum.map(fn {path, module, params} ->
      {path, FancyLink.get_fancy_link_title(module, params)}
    end)
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
      |> assign(:should_hide, is_nil(side_nav))
      |> assign(:history, get_history(assigns.current_user))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("global_navigate", %{"to" => to}, socket) do
    new_history =
      if socket.assigns.current_user do
        [url_without_params | _] = String.split(to, "?")
        {_, module, params} = FancyLink.build_route_tuple(url_without_params)

        new_title = FancyLink.get_fancy_link_title(module, params)

        if new_title do
          socket.assigns.current_user.id
          |> History.save_url(url_without_params)
          |> build_formatted_history()
          |> dbg
        end
      end

    dbg(new_history)

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
    <nav class={if @should_hide, do: "hidden"} phx-hook="SideNav" id="js-side-nav">
      <%= for link <- @side_nav do %>
        <.link navigate={link.to}><%= link.label %></.link>
        <div :if={Map.has_key?(link, :children) and length(link.children) > 0} class="side-link-group">
          <.link :for={child <- link.children} navigate={child.to}>
            <%= child.label %>
          </.link>
        </div>
      <% end %>
      <%= if @history do %>
        <strong>History</strong>
        <div class="side-link-group history">
          <.link :for={{path, title} <- @history} navigate={path}><%= title %></.link>
        </div>
      <% end %>
    </nav>
    """
  end
end
