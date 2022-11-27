defmodule Purple.TransactionParser do
  @callback label() :: String.t()
  @callback parse_dollars([Map.t()]) :: String.t()
  @callback parse_merchant([Map.t()]) :: String.t()
  @callback parse_last_4([Map.t()]) :: String.t()
  @callback parse_datetime([Map.t()]) :: DateTime.t() | nil

  def get_cents(doc, impl) do
    doc
    |> impl.parse_dollars()
    |> Purple.Finance.Transaction.dollars_to_cents()
  end

  def get_merchant(doc, impl) do
    doc
    |> impl.parse_merchant()
    |> Purple.titleize()
  end

  def get_payment_method(doc, impl) do
    case impl.parse_last_4(doc) do
      last_4 when is_binary(last_4) -> "CC " <> last_4
      _ -> nil
    end
  end

  def get_timestamp(doc, impl) do
    try do
      case impl.parse_datetime(doc) do
        dt = %DateTime{} -> Purple.Date.to_naive_datetime(dt)
        _ -> nil
      end
    rescue
      ArgumentError ->
        nil
    end
  end

  def get_params(doc, impl) do
    params = %{
      cents: get_cents(doc, impl),
      merchant: get_merchant(doc, impl),
      notes: "\n------\nParsed with:\n`#{impl.label()}`\n",
      payment_method: get_payment_method(doc, impl),
      timestamp: get_timestamp(doc, impl)
    }

    case Enum.find(params, fn
           {_, cents} when is_integer(cents) -> cents < 1
           {_, val} -> is_nil(val)
         end) do
      nil -> {:ok, params}
      {key, val} -> {:error, "failed to parse #{key} in #{impl.label()}: #{val}"}
    end
  end

  def parse_html(email_content) do
    case Floki.parse_document(email_content) do
      {:ok, doc} -> {:ok, Floki.find(doc, "html")}
      err -> err
    end
  end
end
