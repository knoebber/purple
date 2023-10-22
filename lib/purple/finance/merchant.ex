defmodule Purple.Finance.Merchant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "merchants" do
    field :category, Ecto.Enum, values: Purple.Finance.Choices.category_values(), default: :OTHER
    field :description, :string, default: ""
    # deprecated
    field :name, :string

    field :primary_name, :string, virtual: true

    has_many :transactions, Purple.Finance.Transaction

    has_many :names, Purple.Finance.MerchantName

    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.MerchantTag

    timestamps()
  end

  def set_primary_name(%__MODULE__{names: names} = merchant)
      when is_list(names) and length(names) > 0 do
    primary_merchant_name = Enum.find(merchant.names, & &1.is_primary) || hd(merchant.names)
    Map.put(
      merchant,
      :primary_name,
      primary_merchant_name.name
    )
  end

  def set_primary_name(%__MODULE__{} = m) do
    # TODO: remove this after every merchant has a name set.
    m
  end

  def changeset(merchant, attrs) do
    merchant
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name, message: "already exists")
  end
end
