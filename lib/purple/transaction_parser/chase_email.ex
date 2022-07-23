defmodule Purple.TransactionParser.ChaseEmail do
  @behaviour Purple.TransactionParser

  @impl true
  def parse_cents(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('amount') + td")
    |> Floki.text()
    |> Purple.dollars_to_cents()
  end

  @impl true
  def parse_merchant(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('merchant') + td")
    |> Floki.text()
  end

  @impl true
  def parse_payment_method(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('account') + td")
    |> Floki.text()
  end

  def parse_timestamp(date_string) when is_binary(date_string) do
    # "Jul 11, 2022 at 7:32 PM ET"
    [
      month_string,
      day_string,
      year_string,
      _,
      time_string,
      pm_string,
      tz_string
    ] = String.split(date_string, " ")

    [
      hour_string,
      minute_string
    ] = String.split(time_string, ":")

    DateTime.new!(
      Date.new!(
        Purple.parse_int(year_string),
        Purple.month_name_to_number(month_string),
        Purple.parse_int(day_string)
      ),
      Time.new!(
        Purple.hour_to_number(hour_string, pm_string),
        Purple.parse_int(minute_string),
        0
      ),
      Purple.get_tzname(tz_string)
    )
    |> Purple.to_naive_datetime()
  end

  @impl true
  def parse_timestamp(doc) when is_list(doc) do
    doc
    |> Floki.find("td:fl-icontains('date') + td")
    |> Floki.text()
    |> parse_timestamp
  end
end
