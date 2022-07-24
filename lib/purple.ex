defmodule Purple do
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
    |> DateTime.shift_zone!(Purple.default_tz())
    |> DateTime.to_date()
  end

  def unix_to_naive(unix) do
    unix
    |> DateTime.from_unix!()
    |> DateTime.to_naive()
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

  def parse_int(s) do
    {int, _} = Integer.parse(s)
    int
  end

  def parse_int(s, minimum) when is_binary(s) do
    case Integer.parse(s) do
      {n, ""} -> max(n, minimum)
      _ -> minimum
    end
  end

  def parse_int(_, min), do: min

  def parse_int(s, minimum, maximum) do
    min(parse_int(s, minimum), maximum)
  end

  defp date_from_map(m = %{}) do
    with {year, ""} <- Integer.parse(Map.get(m, "year")),
         {month, ""} <- Integer.parse(Map.get(m, "month")),
         {day, ""} <- Integer.parse(Map.get(m, "day")) do
      Date.new(year, month, day)
    else
      _ -> :invalid
    end
  end

  defp time_from_map(m = %{}) do
    Time.new(
      Map.get(m, "hour") |> parse_int(0),
      Map.get(m, "minute") |> parse_int(0),
      Map.get(m, "second") |> parse_int(0),
      0
    )
  end

  def local_datetime_from_map(m = %{}) do
    with {:ok, date} <- date_from_map(m),
         {:ok, time} <- time_from_map(m) do
      DateTime.new!(date, time, default_tz())
    else
      _ -> DateTime.shift_zone!(DateTime.utc_now(), default_tz())
    end
  end

  def naive_datetime_from_map(m = %{}) do
    m
    |> local_datetime_from_map()
    |> to_naive_datetime()
  end

  def dollars_to_cents([]) do
    0
  end

  def dollars_to_cents([dollars]) do
    String.to_integer(dollars) * 100
  end

  def dollars_to_cents([dollars, cents]) do
    dollars_to_cents([dollars]) + String.to_integer(cents)
  end

  def dollars_to_cents(<<?$, rest::binary>>), do: dollars_to_cents(rest)

  def dollars_to_cents(dollars) when is_binary(dollars) do
    if Regex.match?(~r/^\$?[0-9]+(\.[0-9]{1,2})?$/, dollars) do
      dollars_to_cents(String.split(dollars, "."))
    else
      0
    end
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

  def hour_to_number(hour_string, "AM"), do: parse_int(hour_string)
  def hour_to_number(hour_string, "PM"), do: parse_int(hour_string) + 12

  def get_tzname("ET"), do: "America/New_York"
  def get_tzname(tz), do: tz

  def scan_4_digits(string) do
    case Regex.run(~r/\d{4}/, string) do
      [four] -> four
      _ -> nil
    end
  end

  def titleize(string) do
    string
    |> String.split
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
