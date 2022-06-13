defmodule Purple.Finance.SharedTransaction do
  use Ecto.Schema

  schema "shared_transactions" do
    timestamps(updated_at: false)

    belongs_to :shared_budget, Purple.Finance.SharedBudget
    belongs_to :transaction, Purple.Finance.Transaction
  end
end
