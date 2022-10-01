defmodule Purple.TransactionParser.BOAEmail do
  require Logger

  @behaviour Purple.TransactionParser

  @impl true
  def label(), do: "Bank of America Email"

  @impl true
  def parse_dollars(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('amount') + td")
    |> Floki.text()
  end

  @impl true
  def parse_merchant(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('where') + td")
    |> Floki.text()
  end

  @impl true
  def parse_last_4(doc) when is_list(doc) do
    doc
    |> Floki.find("td > b:fl-icontains('ending in')")
    |> Floki.text()
    |> Purple.scan_4_digits()
  end

  def parse_datetime(date_string) when is_binary(date_string) do
    # "July 23, 2022"
    case String.split(date_string, " ") do
      [month_string, day_string, year_string] ->
        DateTime.new!(
          Date.new!(
            Purple.parse_int(year_string),
            Purple.month_name_to_number(month_string),
            Purple.parse_int(day_string)
          ),
          Time.new!(
            12,
            0,
            0
          ),
          Purple.default_tz()
        )

      _ ->
        Logger.error("#{__MODULE__}: failed to parse date string \"#{date_string}\"")
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
