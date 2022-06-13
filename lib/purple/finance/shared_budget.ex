defmodule Purple.Finance.SharedBudget do
  use Ecto.Schema

  schema "shared_budgets" do
    timestamps(updated_at: false)

    has_many :shared_transactions, Purple.Finance.SharedTransaction
  end
end
