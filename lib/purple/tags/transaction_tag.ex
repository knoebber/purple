defmodule Purple.Tags.TransactionTag do
  use Ecto.Schema

  schema "transaction_tags" do
    belongs_to :transaction, Purple.Finance.Transaction
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
