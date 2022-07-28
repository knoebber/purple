defmodule Purple.TransactionParser do
  alias Purple.Repo
  alias Purple.Finance
  alias Purple.Finance.Transaction

  @callback label() :: String.t()
  @callback parse_dollars([Map.t()]) :: String.t()
  @callback parse_merchant([Map.t()]) :: String.t()
  @callback parse_last_4([Map.t()]) :: String.t()
  @callback parse_datetime([Map.t()]) :: DateTime.t() | nil

  # REMOVE ME
  def save(tx_map, user_id) do
    Repo.transaction(fn ->
      merchant = Finance.get_or_create_merchant!(tx_map.merchant)
      payment_method = Finance.get_or_create_payment_method!(tx_map.payment_method)

      Repo.insert!(%Transaction{
        cents: tx_map.cents,
        description: tx_map.description,
        merchant_id: merchant.id,
        notes: tx_map.notes,
        payment_method_id: payment_method.id,
        timestamp: tx_map.timestamp,
        user_id: user_id
      })
    end)
  end

  def get_cents(doc, impl) do
    doc
    |> impl.parse_dollars()
    |> Purple.dollars_to_cents()
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
    case impl.parse_datetime(doc) do
      dt = %DateTime{} -> Purple.to_naive_datetime(dt)
      _ -> nil
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

    if Enum.all?(params, fn
         {_, cents} when is_integer(cents) -> cents > 0
         {_, val} -> !!val
       end) do
      {:ok, params}
    else
      {:error, impl.label() <> " failed to parse all fields: " <> inspect(params)}
    end
  end

  def parse_html(email_content) do
    case Floki.parse_document(email_content) do
      {:ok, doc} -> {:ok, Floki.find(doc, "html")}
      err -> err
    end
  end
end
