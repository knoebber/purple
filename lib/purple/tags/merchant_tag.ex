defmodule Purple.Tags.MerchantTag do
  use Ecto.Schema

  schema "merchant_tags" do
    belongs_to :merchant, Purple.Finance.Merchant
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
