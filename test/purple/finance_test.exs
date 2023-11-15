defmodule Purple.FinanceTest do
  alias Purple.Finance.{
    Transaction,
    Merchant,
    PaymentMethod,
    MerchantName,
    ImportedTransaction,
    TransactionImportTask
  }

  import Purple.AccountsFixtures
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

    test "save imported transaction" do
      u = user_fixture()

      tit =
        Repo.insert!(%TransactionImportTask{
          parser: Purple.TransactionParser.BOAEmail,
          status: :ACTIVE,
          user_id: u.id,
          email_label: ""
        })

      olive = get_or_create_merchant!("Olive 🫒")
      {:ok, _} = update_merchant(olive.merchant, %{"description" => "#home"})
      Purple.Tags.sync_tags(olive.merchant_id, :merchant)
      assert [%Purple.Tags.Tag{name: "home"}] = get_merchant!(olive.merchant_id, :tags).tags

      get_params = fn
        p ->
          %{
            transaction_params:
              Enum.into(
                p,
                %{
                  cents: 42069,
                  merchant: olive.name,
                  notes: "default get_params note",
                  payment_method: "CC 💳 27",
                  user_id: u.id,
                  timestamp: Purple.Date.utc_now()
                }
              ),
            imported_transaction: %ImportedTransaction{
              transaction_import_task_id: tit.id,
              data_id: "#{System.unique_integer()}",
              data_summary: "whatever."
            }
          }
      end

      assert {:ok, {%Transaction{id: id}, %ImportedTransaction{}}} =
               save_imported_transaction(get_params.(%{}))

      tx = get_transaction!(id)
      assert tx.category == :HOME

      {:ok, _} = give_name_to_merchant(olive.merchant, "Apple 🍏")
      {:ok, _} = update_merchant(olive.merchant, %{"category" => :SOFTWARE})

      assert {:ok, {%Transaction{id: id}, %ImportedTransaction{}}} =
               save_imported_transaction(get_params.(%{merchant: "Apple 🍏"}))

      tx = get_transaction!(id)
      assert tx.merchant_name.name == "Apple 🍏"
      assert tx.merchant_name.merchant_id == olive.merchant_id
      assert tx.category == :SOFTWARE
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

    test "merge merchants" do
      main_merchant = merchant_name_fixture("main merchant").merchant
      to_merge_merchant = merchant_name_fixture("to merge merchant").merchant
      give_name_to_merchant(main_merchant, "foo")
      give_name_to_merchant(to_merge_merchant, "bar")

      {:ok, main_merchant} =
        update_merchant(main_merchant, %{
          "description" => "Tags :) \n\n#apple\n\n#orange"
        })

      {:ok, to_merge_merchant} =
        update_merchant(to_merge_merchant, %{
          "description" => "Tags :) \n\n#apple\n\n#orange #uniquetag"
        })

      Purple.Tags.sync_tags(main_merchant.id, :merchant)
      Purple.Tags.sync_tags(to_merge_merchant.id, :merchant)

      merge_merchants(main_merchant, to_merge_merchant)

      assert is_nil(get_merchant(to_merge_merchant.id))

      result = get_merchant!(main_merchant.id, :tags)
      assert for tag <- result.tags, do: tag.name == ["apple", "orange", "uniquetag"]
      assert result.primary_name == "main merchant"

      assert for name <- result.names,
                 do: name.name == ["main merchant", "to merge merchant", "foo", "bar"]
    end
  end
end
