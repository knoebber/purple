defmodule Purple.TransactionParser.ChaseEmail do
  alias Purple.Finance.Transaction

  @behaviour Purple.TransactionParser

  defp parse_from_document(doc) do
    cents =
      doc
      |> Floki.find("td:fl-icontains('Amount') + td")
      |> Floki.text()
      |> Purple.dollars_to_cents()

    date =
      doc
      |> Floki.find("td:fl-icontains('Date') + td")
      |> Floki.text()

    payment_method =
      doc
      |> Floki.find("td:fl-icontains('Account') + td")
      |> Floki.text()

    merchant =
      doc
      |> Floki.find("td:fl-icontains('Merchant') + td")
      |> Floki.text()

    IO.inspect([cents, date, payment_method, merchant])

    {:ok, %Transaction{}}
  end

  @impl true
  def parse(email_content) do
    case Floki.parse_document(email_content) do
      {:ok, doc} -> parse_from_document(Floki.find(doc, "html"))
      {:error, reason} -> {:error, reason}
    end
  end
end
