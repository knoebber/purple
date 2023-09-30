defmodule Purple.KeyValueTest do
  use Purple.DataCase
  alias Purple.KeyValue

  describe "key value test" do
    test "delete, get, and insert" do
      assert is_nil(KeyValue.get("foo"))
      assert is_nil(KeyValue.get(1))
      assert is_nil(KeyValue.get(:foo))

      KeyValue.insert("int", 1)
      KeyValue.insert(:str, "string")
      KeyValue.insert("map", %{foo: "bar"})
      KeyValue.insert(:arr, [1, 2, 3])

      assert 1 = KeyValue.get("int")
      assert "string" = KeyValue.get(:str)
      assert %{foo: "bar"} = KeyValue.get("map")
      assert [1, 2, 3] = KeyValue.get(:arr)

      KeyValue.delete("int")
      KeyValue.delete(:str)
      KeyValue.delete("map")
      KeyValue.delete(:arr)

      assert is_nil(KeyValue.get("int"))
      assert is_nil(KeyValue.get(:str))
      assert is_nil(KeyValue.get("map"))
      assert is_nil(KeyValue.get(:arr))
    end
  end
end
