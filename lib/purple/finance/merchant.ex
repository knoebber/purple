defmodule Purple.Finance.Merchant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "merchants" do
    field :name, :string
    field :description, :string, default: ""

    has_many :transactions, Purple.Finance.Transaction
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.MerchantTag

    timestamps()
  end

  def changeset(merchant, attrs) do
    merchant
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name, message: "already exists")
  end
end
