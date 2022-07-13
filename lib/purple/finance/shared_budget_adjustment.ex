defmodule Purple.Finance.SharedBudgetAdjustment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shared_budget_adjustments" do
    field :cents, :integer
    field :description, :string, default: ""
    field :notes, :string, default: ""
    field :type, Ecto.Enum, values: [:SHARE, :CREDIT], default: :SHARE

    field :dollars, :string, default: "", virtual: true

    timestamps()

    belongs_to :shared_budget, Purple.Finance.SharedBudget
    belongs_to :user, Purple.Accounts.User
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.SharedBudgetAdjustmentTag
  end

  defp set_cents(changeset) do
    put_change(
      changeset,
      :cents,
      Purple.dollars_to_cents(get_field(changeset, :dollars))
    )
  end

  def changeset(adjustment, attrs) do
    adjustment
    |> cast(attrs, [
      :user_id,
      :description,
      :dollars,
      :notes,
      :type
    ])
    |> validate_required([:dollars, :user_id])
    |> set_cents
    |> validate_number(:cents, greater_than: 99, message: "Must be at least 1 dollar")
  end
end
