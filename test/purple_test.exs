defmodule Purple.FinanceTest do
  use Purple.DataCase

  describe "purple" do
    test "get_cents\1" do
      assert Purple.get_cents("12-3.42") == 0
      assert Purple.get_cents("-123.42") == 0
      assert Purple.get_cents("$-1") == 0
      assert Purple.get_cents("$-1.-123") == 0
      assert Purple.get_cents("") == 0
      assert Purple.get_cents("$") == 0
      assert Purple.get_cents(".") == 0
      assert Purple.get_cents("0") == 0
      assert Purple.get_cents("09.99") == 999
      assert Purple.get_cents("1.01") == 101
      assert Purple.get_cents("1.99") == 199
      assert Purple.get_cents("$1") == 100
      assert Purple.get_cents("$1.0") == 100
      assert Purple.get_cents("$1.00") == 100
      assert Purple.get_cents("$1.0001") == 0
      assert Purple.get_cents("69") == 6900
      assert Purple.get_cents("52.52") == 5252
      assert Purple.get_cents("420.42") == 420 * 100 + 42
    end
  end
end
