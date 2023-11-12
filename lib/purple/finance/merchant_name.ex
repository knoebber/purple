defmodule Purple.Finance.MerchantName do
  use Ecto.Schema
  import Ecto.Changeset

  schema "merchant_names" do
    field :name, :string
    field :is_primary, :boolean, default: false

    has_many :transactions, Purple.Finance.Transaction
    belongs_to :merchant, Purple.Finance.Merchant

    timestamps()
  end

  def changeset(%__MODULE__{} = name, attrs) do
    cast(name, attrs, [:name, :is_primary])
  end
end
