defmodule Purple.Date do
  @naive_tz "Etc/UTC"

  def default_tz do
    Application.get_env(:purple, :default_tz)
  end

  def utc_now do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end

  def local_now do
    DateTime.shift_zone!(DateTime.utc_now(), default_tz())
  end

  def local_date do
    DateTime.utc_now()
    |> DateTime.shift_zone!(default_tz())
    |> DateTime.to_date()
  end

  def unix_to_naive(unix) do
    unix
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
  end

  def unix_now() do
    System.os_time(:second)
  end

  def to_local_datetime(%NaiveDateTime{} = ndt) do
    ndt
    |> DateTime.from_naive!(@naive_tz)
    |> DateTime.shift_zone!(default_tz())
  end

  def to_local_datetime(%DateTime{} = dt) do
    DateTime.shift_zone!(dt, default_tz())
  end

  def to_naive_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!(@naive_tz)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end

  defp date_from_map(%{} = m) do
    with {year, ""} <- Integer.parse(Map.get(m, "year")),
         {month, ""} <- Integer.parse(Map.get(m, "month")),
         {day, ""} <- Integer.parse(Map.get(m, "day")) do
      Date.new(year, month, day)
    else
      _ -> :invalid
    end
  end

  defp time_from_map(%{} = m) do
    Time.new(
      Purple.parse_int(Map.get(m, "hour"), 0),
      Purple.parse_int(Map.get(m, "minute"), 0),
      Purple.parse_int(Map.get(m, "second"), 0),
      0
    )
  end

  def local_datetime_from_map(%{} = m) do
    with {:ok, date} <- date_from_map(m),
         {:ok, time} <- time_from_map(m) do
      DateTime.new!(date, time, default_tz())
    else
      _ -> DateTime.shift_zone!(DateTime.utc_now(), default_tz())
    end
  end

  def naive_datetime_from_map(%{} = m) do
    m
    |> local_datetime_from_map()
    |> to_naive_datetime()
  end

  def month_name_to_number(month_name) do
    Enum.find_index(
      [
        "JAN",
        "FEB",
        "MAR",
        "APR",
        "MAY",
        "JUN",
        "JUL",
        "AUG",
        "SEP",
        "OCT",
        "NOV",
        "DEC"
      ],
      fn m ->
        month_name
        |> String.slice(0, 3)
        |> String.upcase() == m
      end
    ) + 1
  end

  def hour_to_number("12", "AM"), do: 0
  def hour_to_number("12", "PM"), do: 12
  def hour_to_number(hour_string, "AM"), do: Purple.parse_int!(hour_string)
  def hour_to_number(hour_string, "PM"), do: Purple.parse_int!(hour_string) + 12

  def get_tzname("ET"), do: "America/New_York"
  def get_tzname(tz), do: tz

  def format(%Date{} = d) do
    Calendar.strftime(d, "%m/%d/%Y")
  end

  def format(%NaiveDateTime{} = ndt) do
    ndt
    |> to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y")
  end

  def format(%NaiveDateTime{} = ndt, :time) do
    ndt
    |> to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y %I:%M%P")
  end

  def format(%NaiveDateTime{} = ndt, :mdy) do
    ndt
    |> to_local_datetime()
    |> Calendar.strftime("%m/%d/%Y")
  end

  def format(%Date{} = d, :dayname) do
    Calendar.strftime(d, "%a %m/%d/%Y")
  end

  def format(%Date{} = d, :month) do
    Calendar.strftime(d, "%B, %Y")
  end
end
