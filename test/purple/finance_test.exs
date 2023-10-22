defmodule Purple.FinanceTest do
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod, MerchantName}
  import Purple.Finance
  import Purple.FinanceFixtures
  use Purple.DataCase

  describe "can create basic resources" do
    test "fixtures work" do
      assert %Transaction{} = transaction_fixture()
      assert %PaymentMethod{} = payment_method_fixture()
      assert %MerchantName{merchant: %Merchant{}} = merchant_name_fixture()
    end
  end

  describe "transaction" do
    test "dollars_to_cents\1" do
      assert Transaction.dollars_to_cents("12-3.42") == 0
      assert Transaction.dollars_to_cents("-123.42") == 0
      assert Transaction.dollars_to_cents("$-1") == 0
      assert Transaction.dollars_to_cents("$-1.-123") == 0
      assert Transaction.dollars_to_cents("") == 0
      assert Transaction.dollars_to_cents("$") == 0
      assert Transaction.dollars_to_cents(".") == 0
      assert Transaction.dollars_to_cents("0") == 0
      assert Transaction.dollars_to_cents("09.99") == 999
      assert Transaction.dollars_to_cents("1.01") == 101
      assert Transaction.dollars_to_cents("1.99") == 199
      assert Transaction.dollars_to_cents("$1") == 100
      assert Transaction.dollars_to_cents("$1.0") == 100
      assert Transaction.dollars_to_cents("$1.00") == 100
      assert Transaction.dollars_to_cents("$1.0001") == 0
      assert Transaction.dollars_to_cents("69") == 6900
      assert Transaction.dollars_to_cents("52.52") == 5252
      assert Transaction.dollars_to_cents("420.42") == 420 * 100 + 42
      assert Transaction.dollars_to_cents("4,200.42") == 4200 * 100 + 42
      assert Transaction.dollars_to_cents("$4,200.42") == 4200 * 100 + 42
      assert Transaction.dollars_to_cents("$1,123,435.69") == 1_123_435 * 100 + 69
    end
  end

  describe "merchant" do
    test "merchant names" do
      merchant1 = merchant_name_fixture("pineapple").merchant
      merchant2 = merchant_name_fixture("grape").merchant

      assert {:error, _} = give_name_to_merchant(merchant1, "grape")
      assert {:error, _} = give_name_to_merchant(merchant1, "grape", true)

      assert {:ok, %MerchantName{is_primary: false, name: "blueberry"}} =
               give_name_to_merchant(merchant1, "blueberry")

      assert {:ok, %MerchantName{is_primary: true, name: "blueberry"}} =
               give_name_to_merchant(merchant1, "blueberry", true)

      # duplicate call should be noop
      assert {:ok, %MerchantName{is_primary: true, name: "blueberry"}} =
               give_name_to_merchant(merchant1, "BLUEBERRY", true)

      merchant1 = get_merchant(merchant1.id)

      assert [
               %MerchantName{name: "blueberry", is_primary: true},
               %MerchantName{name: "pineapple", is_primary: false}
             ] = merchant1.names

      assert merchant1.primary_name == "blueberry"
      assert merchant1.id == get_merchant_by_name("BLUEBERRY").id
      assert merchant1.id == get_merchant_by_name("PineApplE").id

      # ok to give 'pineapple' to merchant 2 since it's non primary
      assert {:ok, _} = give_name_to_merchant(merchant2, "pineapple", true)
      merchant2 = get_merchant(merchant2.id)

      assert [
               %MerchantName{name: "pineapple", is_primary: true},
               %MerchantName{name: "grape", is_primary: false}
             ] = merchant2.names

      assert merchant2.primary_name == "pineapple"

      assert {:ok, _} = give_name_to_merchant(merchant2, "grape", true)
      merchant2 = get_merchant(merchant2.id)

      assert [
               %MerchantName{name: "grape", is_primary: true},
               %MerchantName{name: "pineapple", is_primary: false}
             ] = merchant2.names

      assert merchant2.primary_name == "grape"
      assert merchant2.id == get_merchant_by_name("grape").id
      assert merchant2.id == get_merchant_by_name("pineapple").id

      assert nil == get_merchant_by_name("no database match")
    end
  end
end
