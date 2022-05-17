defmodule Purple.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :cents, :integer
    field :description, :string, default: ""
    field :timestamp, :naive_datetime

    field :amount, :string, default: "", virtual: true

    timestamps()

    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :payment_method, Purple.Finance.PaymentMethod
    belongs_to :user, Purple.Accounts.User
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

  def get_cents(amount) when is_binary(amount) do
    if Regex.match?(~r/^\$?[0-9]+(\.[0-9]{1,2})?$/, amount) do
      get_cents(String.split(amount, "."))
    else
      0
    end
  end

  defp set_cents(changeset) do
    amount = get_field(changeset, :amount) |> IO.inspect(label: "amount")
    cents = get_cents(amount) |> IO.inspect(label: "cents")

    changeset
    |> put_change(:cents, cents)
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :amount,
      :description,
      :merchant_id,
      :payment_method_id
    ])
    |> validate_required([
      :amount,
      :merchant_id,
      :payment_method_id
    ])
    |> set_cents
    |> validate_number(:cents, greater_than: 99, message: "Must be at least 1 dollar")
    |> set_timestamp(attrs)
  end
end
