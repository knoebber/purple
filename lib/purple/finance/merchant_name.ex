defmodule Purple.Finance.MerchantName do
  use Ecto.Schema

  schema "merchant_names" do
    field :name, :string
    field :is_primary, :boolean, default: false
    belongs_to :merchant, Purple.Finance.Merchant

    timestamps()
  end
end
