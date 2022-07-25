defmodule Purple.Finance.ImportedTransaction do
  use Ecto.Schema

  schema "imported_transactions" do
    field :data_id, :string
    belongs_to :transaction, Purple.Finance.Transaction
    belongs_to :transaction_import_task, Purple.Finance.TransactionImportTask

    timestamps()
  end
end
