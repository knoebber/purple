defmodule Purple.TransactionParser do
  alias Purple.Repo
  alias Purple.Finance
  alias Purple.Finance.Transaction

  @callback parse_cents([Map.t()]) :: number
  @callback parse_merchant([Map.t()]) :: String.t()
  @callback parse_payment_method([Map.t()]) :: String.t()
  @callback parse_timestamp([Map.t()]) :: NaiveDateTime.t()

  def save(tx_map, impl, user_id) do
    %Transaction{
      cents: tx_map.cents,
      description: "",
      timestamp: tx_map.timestamp,
      notes: "\n------\nParsed with #{impl}"
    }

    Repo.transaction(fn ->
      merchant = Finance.get_or_create_merchant!(tx_map.merchant)
      payment_method = Finance.get_or_create_payment_method!(tx_map.payment_method)

      Repo.insert!(%Transaction{
        user_id: user_id,
        cents: tx_map.cents,
        description: "",
        merchant_id: merchant.id,
        notes: "\n------\nParsed with\n```\n#{impl}\n```",
        payment_method_id: payment_method.id,
        timestamp: tx_map.timestamp
      })
    end)
  end

  def get_params(doc, impl) do
    %{
      cents: impl.parse_cents(doc),
      merchant: impl.parse_merchant(doc),
      payment_method: impl.parse_payment_method(doc),
      timestamp: impl.parse_timestamp(doc)
    }
  end

  def parse_html(email_content) do
    case Floki.parse_document(email_content) do
      {:ok, doc} -> {:ok, Floki.find(doc, "html")}
      err -> err
    end
  end

  def parse_and_save(content, impl, user_id) do
    case parse_html(content) do
      {:ok, doc} ->
        doc
        |> get_params(impl)
        |> save(impl, user_id)

      err ->
        err
    end
  end
end
