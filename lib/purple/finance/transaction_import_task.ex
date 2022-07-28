defmodule Purple.Finance.TransactionImportTask do
  alias Purple.TransactionParser.{BOAEmail, ChaseEmail}
  use Ecto.Schema

  schema "transaction_import_tasks" do
    field :parser, Ecto.Enum, values: [BOAEmail, ChaseEmail]
    field :status, Ecto.Enum, values: [:ACTIVE, :PAUSED]
    field :email_label, :string
    belongs_to :user, Purple.Accounts.User

    timestamps()
  end

  def parser_mappings do
    Ecto.Enum.mappings(__MODULE__, :parser)
  end

  def parser_values do
    Ecto.Enum.values(__MODULE__, :parser)
  end
end
