defmodule Purple.Tags.SharedBudgetAdjustmentTag do
  use Ecto.Schema

  schema "shared_budget_adjustment_tags" do
    belongs_to :shared_budget_adjustment, Purple.Finance.SharedBudgetAdjustment
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
