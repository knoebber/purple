defmodule Purple.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :amount, :integer, default: 100
    field :description, :string, default: ""
    field :timestamp, :naive_datetime

    timestamps()

    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :payment_method, Purple.Finance.PaymentMethod
    belongs_to :user, Purple.Accounts.User
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.TransactionTag
  end

  defp set_default_timestamp(changeset) do
    if get_field(changeset, :timestamp) do
      changeset
    else
      put_change(
        changeset,
        :timestamp,
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      )
    end
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [
      :amount,
      :description,
      :timestamp
    ])
    |> validate_number(:amount, greater_than: 99)
    |> set_default_timestamp
  end
end
