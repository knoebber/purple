defmodule Purple.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :cents, :integer, default: 100
    field :description, :string, default: ""
    field :timestamp, :naive_datetime

    timestamps()

    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :payment_method, Purple.Finance.PaymentMethod
    belongs_to :user, Purple.Accounts.User
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.TransactionTag
  end

  defp set_timestamp(changeset, attrs) do
    if get_field(changeset, :timestamp) do
      changeset
    else
      timestamp_attrs = Map.get(attrs, "timestamp")

      put_change(
        changeset,
        :timestamp,
        if is_map(timestamp_attrs) do
          Purple.naive_datetime_from_map(timestamp_attrs)
        else
          Purple.utc_now()
        end
      )
    end
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :cents,
      :description,
      :merchant_id,
      :payment_method_id
    ])
    |> validate_required([
      :cents,
      :merchant_id,
      :payment_method_id
    ])
    |> validate_number(:cents, greater_than: 99)
    |> set_timestamp(attrs)
  end
end
