defmodule Purple.TagsTest do
  use Purple.DataCase

  alias Purple.Tags
  alias Purple.Tags.Tag

  describe "tags" do
    test "extract_tags/1" do
      assert Tags.extract_tags("") == []
      assert Tags.extract_tags("#") == []
      assert Tags.extract_tags("####") == []
      assert Tags.extract_tags("# purple") == []
      assert Tags.extract_tags("#p") == []
      assert Tags.extract_tags("#pa") == ["pa"]
      assert Tags.extract_tags("#pur-ple") == ["pur"]
      assert Tags.extract_tags("#purple\n") == ["purple"]
      assert Tags.extract_tags("\n#purple\n") == ["purple"]
      assert Tags.extract_tags("\n#puRple\n#YELLOW2015#purple") == ["purple", "yellow2015"]
      assert Tags.extract_tags("#one#two#three\n#four#one") == ["one", "two", "three", "four"]
    end

    test "diff_tags/2" do
      a = %Tag{id: 1, name: "one"}
      b = %Tag{id: 2, name: "two"}
      c = %Tag{id: 3, name: "three"}

      assert Tags.diff_tags([], []) == []
      assert Tags.diff_tags([a], [a]) == []
      assert Tags.diff_tags([a], [b]) == [{:insert, b}, {:delete, a}]
      assert Tags.diff_tags([a, b], [b, c]) == [{:insert, c}, {:delete, a}]
    end
  end
end
