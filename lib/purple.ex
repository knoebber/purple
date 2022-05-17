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

  def parse_int(s, default) when is_binary(s) do
    case Integer.parse(s) do
      {n, ""} -> n
      _ -> default
    end
  end

  def parse_int(_, default), do: default

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
end
