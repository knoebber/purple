defmodule PetallerWeb.WrongLive do
  use Phoenix.LiveView, layout: {PetallerWeb.LayoutView, "live.html"}

  def time() do
    DateTime.utc_now()
    |> DateTime.shift_zone!("America/Anchorage")
    |> Calendar.strftime("%I:%M:%S%P")
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       answer: "#{Enum.random(1..10)}",
       message: "Make a guess:",
       score: 0,
       time: time()
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Your score: <%= @score %></h1>
    <h2>It's <%= @time %></h2>
    <h2><%= @message %></h2>
    <h2>
    <%= for n <- 1..10 do %>
    <a href="#" phx-click="guess" phx-value-number={n} ><%= n %></a>
    <% end %>
    </h2>
    """
  end

  def handle_event("guess", %{"number" => guess} = data, socket) do
    IO.inspect(guess)
    IO.inspect(socket.assigns.answer)

    correct = guess == socket.assigns.answer
    score = socket.assigns.score + if(correct, do: 1, else: -1)

    message =
      if(correct, do: "#{guess} is correct!", else: "Your guess: #{guess}. Wrong. Guess again.")

    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score,
        time: time()
      )
    }
  end
end
