defmodule Purple.FinanceTest do
  use Purple.DataCase
  alias Purple.Finance.Transaction

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
end
