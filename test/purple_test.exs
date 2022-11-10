defmodule Purple.PurpleTest do
  use Purple.DataCase
  import Purple

  describe "purple" do
   test "titleize/1" do
      assert titleize("") == ""
      assert titleize("ok ok") == "Ok Ok"
    end
  end
end
