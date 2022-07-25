defmodule Purple.Finance.TransactionImportTask do
  alias Purple.TransactionParser.{BOAEmail, ChaseEmail}
  use Ecto.Schema

  schema "transaction_import_tasks" do
    field :parser, Ecto.Enum, values: [BOAEmail, ChaseEmail]
    field :status, Ecto.Enum, values: [:PERIOD, :MANUAL, :PAUSED]
    field :email_label, :string
    belongs_to :user, Purple.Accounts.User

    timestamps()
  end
end
