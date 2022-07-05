defmodule Purple.Finance.SharedBudget do
  use Ecto.Schema

  schema "shared_budgets" do
    field :name, :string, default: ""

    timestamps(updated_at: false)

    has_many :shared_transactions, Purple.Finance.SharedTransaction
    has_many :adjustments, Purple.Finance.SharedBudgetAdjustment
  end
end
