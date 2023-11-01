defmodule Purple.FinanceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Finance` context.
  """

  alias Purple.Finance

  def valid_tx_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      timestamp: %{"day" => "12", "hour" => "7", "month" => "10", "year" => "2023"},
      dollars: "4.20",
      description: "bought a cool thing 😎",
      notes: "yes.\n\nvery cool transaction notes",
      category: :OTHER
    })
  end

  def merchant_name_fixture(name \\ "U can buy stuff here 4 💸") do
    %Finance.MerchantName{} = merchant_name = Finance.get_or_create_merchant!(name)

    {:ok, m} =
      Finance.update_merchant(merchant_name.merchant, %{
        "description" => "default description for merchant fixture"
      })

    Map.put(merchant_name, :merchant, Finance.get_merchant!(m.id))
  end

  def payment_method_fixture(name \\ "CC 4200 💳") do
    Finance.get_or_create_payment_method!(name)
  end

  def transaction_fixture(attrs \\ %{}, keywords \\ []) when is_map(attrs) do
    user = Keyword.get_lazy(keywords, :user, &Purple.AccountsFixtures.user_fixture/0)
    payment_method = Keyword.get_lazy(keywords, :payment_method, &payment_method_fixture/0)
    merchant_name = Keyword.get_lazy(keywords, :merchant_name, &merchant_name_fixture/0)

    attrs =
      Map.merge(
        valid_tx_attributes(attrs),
        %{
          merchant_name_id: merchant_name.id,
          payment_method_id: payment_method.id
        }
      )

    {:ok, tx} = Finance.create_transaction(user.id, attrs)
    Finance.get_transaction!(tx.id)
  end
end
