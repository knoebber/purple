defmodule Purple.Finance.MerchantNameGroup do
  # TODO - delete
  use Ecto.Schema

  schema "merchant_name_groups" do
    field :is_primary, :boolean, default: false
    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :merchant_name, Purple.Finance.MerchantName

    timestamps(updated_at: false)
  end
end
