defmodule Purple.Finance.SharedTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shared_transactions" do
    timestamps(updated_at: false)
    field :type, Ecto.Enum, values: [:SHARE, :CREDIT], default: :SHARE

    belongs_to :shared_budget, Purple.Finance.SharedBudget
    belongs_to :transaction, Purple.Finance.Transaction
  end

  def changeset(shared_transaction, attrs) do
    shared_transaction
    |> cast(attrs, [
      :transaction_id,
      :type
    ])
    |> validate_required([
      :transaction_id,
      :type
    ])
  end
end
