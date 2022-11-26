defmodule Purple.Finance.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :cents, :integer
    field :description, :string, default: ""
    field :timestamp, :naive_datetime
    field :notes, :string, default: ""

    field :dollars, :string, default: "", virtual: true

    timestamps()

    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :payment_method, Purple.Finance.PaymentMethod
    belongs_to :user, Purple.Accounts.User
    has_many :shared_transaction, Purple.Finance.SharedTransaction
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.TransactionTag
  end

  def to_string(transaction = %__MODULE__{}) do
    transaction.dollars <>
      " " <>
      transaction.merchant.name <> " " <> Purple.Date.format(transaction.timestamp)
  end

  def dollars_to_cents([]) do
    0
  end

  def dollars_to_cents([dollars]) do
    String.to_integer(dollars) * 100
  end

  def dollars_to_cents([dollars, cents]) do
    dollars_to_cents([dollars]) + String.to_integer(cents)
  end

  def dollars_to_cents(<<?$, rest::binary>>), do: dollars_to_cents(rest)

  def dollars_to_cents(dollars) when is_binary(dollars) do
    dollars = String.replace(dollars, ",", "")

    if dollars =~ ~r/^\$?[0-9]+(\.[0-9]{1,2})?$/ do
      dollars_to_cents(String.split(dollars, "."))
    else
      0
    end
  end

  def format_cents(cents) when is_integer(cents) do
    "$" <>
      (div(cents, 100) |> Integer.to_string()) <>
      "." <>
      (rem(cents, 100) |> Integer.to_string() |> String.pad_trailing(2, "0"))
  end

  defp set_timestamp(changeset, attrs) do
    timestamp_attrs = Map.get(attrs, "timestamp")

    if is_map(timestamp_attrs) do
      put_change(
        changeset,
        :timestamp,
        Purple.Date.naive_datetime_from_map(timestamp_attrs)
      )
    else
      changeset
    end
  end

  defp set_cents(changeset) do
    put_change(
      changeset,
      :cents,
      dollars_to_cents(get_field(changeset, :dollars))
    )
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :description,
      :dollars,
      :merchant_id,
      :notes,
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
