defmodule Purple.PurpleTest do
  use Purple.DataCase
  import Purple

  describe "purple" do
    test "titleize/1" do
      assert titleize("") == ""
      assert titleize("ok ok") == "Ok Ok"
    end

    test "parse_int/2" do
      assert parse_int("notanumber", 1) == 1
      assert parse_int("notanumber", nil) == nil 
      assert parse_int(nil, 123) == 123 
      assert parse_int("123", nil) == 123 
      assert parse_int("-123", nil) == -123 
    end
  end
end
