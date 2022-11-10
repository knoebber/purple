defmodule Purple.TransactionParser.ChaseEmail do
  require Logger

  @behaviour Purple.TransactionParser

  @impl true
  def label(), do: "Chase Email"

  @impl true
  def parse_dollars(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('amount') + td")
    |> Floki.text()
  end

  @impl true
  def parse_merchant(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('merchant') + td")
    |> Floki.text()
  end

  @impl true
  def parse_last_4(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('account') + td")
    |> Floki.text()
    |> Purple.scan_4_digits()
  end

  def parse_datetime(date_string) when is_binary(date_string) do
    # "Jul 11, 2022 at 7:32 PM ET"
    with [
           month_string,
           day_string,
           year_string,
           _,
           time_string,
           pm_string,
           tz_string
         ] <- String.split(date_string, " "),
         [
           hour_string,
           minute_string
         ] <- String.split(time_string, ":") do
      DateTime.new!(
        Date.new!(
          Purple.parse_int(year_string),
          Purple.Date.month_name_to_number(month_string),
          Purple.parse_int(day_string)
        ),
        Time.new!(
          Purple.Date.hour_to_number(hour_string, pm_string),
          Purple.parse_int(minute_string),
          0
        ),
        Purple.Date.get_tzname(tz_string)
      )
    else
      _ ->
        Logger.error("#{__MODULE__}: failed to parse date_string \"#{date_string}\"")
        nil
    end
  end

  @impl true
  def parse_datetime(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('date') + td")
    |> Floki.text()
    |> parse_datetime
  end
end
