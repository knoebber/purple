defmodule PurpleWeb.Formatters do
  defp is_positive_number(i) do
    is_number(i) and i > 0
  end

  def format_pace(miles, duration_in_seconds) do
    if is_positive_number(miles) and is_positive_number(duration_in_seconds) do
      seconds_per_mile = floor(duration_in_seconds / miles)
      minutes_per_mile = div(seconds_per_mile, 60)
      minute_seconds_per_mile = rem(seconds_per_mile, 60)

      String.replace_prefix(
        format_duration(0, minutes_per_mile, minute_seconds_per_mile),
        "00:",
        ""
      )
    else
      "N/A"
    end
  end

  def format_cents(cents) when is_integer(cents) do
    "$" <>
      (div(cents, 100) |> Integer.to_string()) <>
      "." <>
      (rem(cents, 100) |> Integer.to_string() |> String.pad_trailing(2, "0"))
  end

  def format_duration(hours, minutes, seconds)
      when is_number(hours) and
             is_number(minutes) and
             is_number(seconds) and
             hours + minutes + seconds > 0 do
    [hours, minutes, seconds]
    |> Enum.map(fn n -> Integer.to_string(n) |> String.pad_leading(2, "0") end)
    |> Enum.join(":")
  end

  def format_duration(_, _, _), do: "N/A"

  def format_date(%Date{} = d) do
    Calendar.strftime(d, "%m/%d/%Y")
  end

  def format_date(%NaiveDateTime{} = ndt) do
    ndt
    |> Purple.to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y")
  end

  def format_date(%NaiveDateTime{} = ndt, :time) do
    ndt
    |> Purple.to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y %I:%M%P")
  end

  def format_date(%NaiveDateTime{} = ndt, :mdy) do
    ndt
    |> Purple.to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y")
  end

  def format_date(%Date{} = d, :dayname) do
    Calendar.strftime(d, "%a %m/%d/%Y")
  end

  def changeset_to_reason_list(%Ecto.Changeset{errors: errors}) do
    Enum.map(
      errors,
      fn {_, {reason, _}} -> reason end
    )
  end

  def text_area_rows(""), do: 3

  def text_area_rows(content) do
    content
    |> String.split("\n")
    |> length()
  end
end
