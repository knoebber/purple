defmodule PurpleWeb.HomeLive do
  use PurpleWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Purple.PubSub, "weather_snapshot")
    end

    {
      :ok,
      socket
      |> assign(:side_nav, if(socket.assigns.current_user, do: [], else: nil))
      |> assign(:page_title, "Home")
      |> assign(:last_weather_snapshot, nil)
    }
  end

  @impl Phoenix.LiveView
  def handle_info({:weather_snapshot, weather_snapshot}, socket) do
    {
      :noreply,
      socket
      |> assign(:last_weather_snapshot, weather_snapshot)
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section>
      <h1>Purple :)</h1>
      <div class="flex">
        <Heroicons.cloud :for={_ <- 1..10} />
      </div>
      <div class="flex">
        <Heroicons.sun :for={_ <- 1..10} />
      </div>
      <div :if={@last_weather_snapshot} class="flex flex-col border border-purple-400 p-2 mb-2">
        <span>Temperature: <strong><%= @last_weather_snapshot.temperature %>f</strong></span>
        <span>Humidity: <strong><%= @last_weather_snapshot.humidity %>%</strong></span>
        <span>Pressure: <strong><%= @last_weather_snapshot.pressure %></strong></span>
      </div>
    </section>
    """
  end
end
