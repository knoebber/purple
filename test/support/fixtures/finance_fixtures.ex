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

  def merchant_fixture(name \\ "U can buy stuff here 4 💸") do
    m = Finance.get_or_create_merchant!(name)
    {:ok, m} = Finance.update_merchant(m, %{"description" => "description for the fixture!"})
    m
  end

  def payment_method_fixture(name \\ "CC 4200 💳") do
    Finance.get_or_create_payment_method!(name)
  end

  def transaction_fixture(attrs \\ %{}, keywords \\ []) do
    user = Keyword.get_lazy(keywords, :user, &Purple.AccountsFixtures.user_fixture/0)
    payment_method = Keyword.get_lazy(keywords, :payment_method, &payment_method_fixture/0)
    merchant = Keyword.get_lazy(keywords, :merchant, &merchant_fixture/0)

    attrs =
      Map.merge(
        valid_tx_attributes(attrs),
        %{
          merchant_id: merchant.id,
          payment_method_id: payment_method.id
        }
      )

    {:ok, tx} = Finance.create_transaction(user.id, attrs)
    tx
  end
end
