defmodule Purple.TransactionParser do
  alias Purple.Repo
  alias Purple.Finance
  alias Purple.Finance.Transaction

  @callback label() :: String.t()
  @callback parse_dollars([Map.t()]) :: String.t()
  @callback parse_merchant([Map.t()]) :: String.t()
  @callback parse_last_4([Map.t()]) :: String.t()
  @callback parse_datetime([Map.t()]) :: DateTime.t()

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

  def get_params(doc, impl) do
    %{
      cents: doc |> impl.parse_dollars() |> Purple.dollars_to_cents(),
      description: "",
      merchant: doc |> impl.parse_merchant() |> Purple.titleize(),
      notes: "\n------\nParsed with\n```\n#{impl}\n```",
      payment_method: "CC " <> impl.parse_last_4(doc),
      timestamp: doc |> impl.parse_datetime() |> Purple.to_naive_datetime()
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
        |> save(user_id)

      err ->
        err
    end
  end
end
