defmodule PetallerWeb.Formatters do
  def format_pace(miles, duration_in_seconds) do
    seconds_per_mile = floor(duration_in_seconds / miles)
    minutes_per_mile = div(seconds_per_mile, 60)
    minute_seconds_per_mile = rem(seconds_per_mile, 60)
    format_duration(0, minutes_per_mile, minute_seconds_per_mile)
  end

  def format_duration(hours, minutes, seconds) do
    Enum.map(
      [hours, minutes, seconds],
      fn n -> Integer.to_string(n) |> String.pad_leading(2, "0") end
    )
    |> Enum.join(":")
  end

  def format_date(naive_dt) do
    DateTime.from_naive!(naive_dt, "Etc/UTC")
    |> DateTime.shift_zone!("America/Anchorage")
    |> Calendar.strftime("%m/%d/%Y %I:%M%P")
  end

  def markdown_to_html(markdown) do
    Earmark.as_html!(markdown)
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end
end
