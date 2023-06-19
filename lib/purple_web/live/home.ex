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
      |> assign(
        :last_weather_snapshot,
        Enum.reduce(weather_snapshot, %{}, fn {key, val}, result ->
          Map.put(
            result,
            key,
            if is_float(val) do
              :erlang.float_to_binary(val, decimals: 1)
            else
              val
            end
          )
        end)
      )
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section>
      <h1>Purple :)</h1>
      <div :if={@last_weather_snapshot} class="flex flex-wrap">
        <div class="compass-wrapper flex-none">
          <div class="line-layer">
            <div class="nw"></div>
            <div class="ne"></div>
            <div class="sw"></div>
            <div class="se"></div>
          </div>
          <div class="compass">
            <div class="n">N</div>
            <div class="w">W</div>
            <div class="s">S</div>
            <div class="e">E</div>
          </div>
          <div
            class="arrow"
            style={"transform: rotate(#{@last_weather_snapshot.wind_direction_degrees}deg)"}
          >
            <span class="icon">
              &uarr;
            </span>
          </div>
        </div>
        <div class="flex-none">
          <table class="text-center">
            <thead>
              <tr>
                <th class="pt-0">Wind Speed m/s</th>
                <th class="pt-0">Fahrenheit</th>
                <th class="pt-0">Humidity</th>
                <th class="pt-0">Pressure</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><%= @last_weather_snapshot.wind_speed_ms %></td>
                <td><%= @last_weather_snapshot.temperature %>°</td>
                <td><%= @last_weather_snapshot.humidity %>%</td>
                <td><%= @last_weather_snapshot.pressure %></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="flex-auto">
          <pre></pre>
        </div>
      </div>
    </section>
    """
  end
end
