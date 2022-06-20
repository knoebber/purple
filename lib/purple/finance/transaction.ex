defmodule Purple.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :cents, :integer
    field :description, :string, default: ""
    field :timestamp, :naive_datetime

    field :dollars, :string, default: "", virtual: true

    timestamps()

    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :payment_method, Purple.Finance.PaymentMethod
    belongs_to :user, Purple.Accounts.User
    has_one :shared_transaction, Purple.Finance.SharedTransaction
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.TransactionTag
  end

  defp set_timestamp(changeset, attrs) do
    timestamp_attrs = Map.get(attrs, "timestamp")

    if is_map(timestamp_attrs) do
      put_change(
        changeset,
        :timestamp,
        Purple.naive_datetime_from_map(timestamp_attrs)
      )
    else
      changeset
    end
  end

  def get_cents([]), do: 0
  def get_cents([dollars]), do: String.to_integer(dollars) * 100
  def get_cents([dollars, cents]), do: get_cents([dollars]) + String.to_integer(cents)
  def get_cents(<<?$, rest::binary>>), do: get_cents(rest)

  def get_cents(dollars) when is_binary(dollars) do
    if Regex.match?(~r/^\$?[0-9]+(\.[0-9]{1,2})?$/, dollars) do
      get_cents(String.split(dollars, "."))
    else
      0
    end
  end

  defp set_cents(changeset) do
    put_change(
      changeset,
      :cents,
      get_cents(get_field(changeset, :dollars))
    )
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :dollars,
      :description,
      :merchant_id,
      :payment_method_id
    ])
    |> validate_required([
      :dollars,
      :merchant_id,
      :payment_method_id
    ])
    |> set_cents
    |> validate_number(:cents, greater_than: 99, message: "Must be at least 1 dollar")
    |> set_timestamp(attrs)
  end
end
