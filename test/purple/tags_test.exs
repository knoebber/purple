defmodule Purple.TagsTest do
  use Purple.DataCase

  alias Purple.Tags
  alias Purple.Tags.Tag

  describe "tags" do
    test "extract_tags_from_markdown\1" do
      assert Tags.extract_tags_from_markdown("#invalid\n```") == []

      result =
        Tags.extract_tags_from_markdown(~s"""
        # header1 #header1

        * #list1
        * #list2
        * 3

        ```
        code #code is a comment not a tag
        ```

        `also invalid #inlinecode`

        https://example.com#linkanchor

        normal #paragraph hashtag
        """)
        |> Enum.sort()

      assert result == ["list1", "list2", "paragraph"]
    end

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
      d = %Tag{id: 4, name: "four"}

      assert Tags.diff_tags([], []) == [add: [], remove: []]
      assert Tags.diff_tags([a], [a]) == [add: [], remove: []]
      assert Tags.diff_tags([b], [a]) == [add: [b], remove: [a]]
      assert Tags.diff_tags([b, c, d], [a, b]) == [add: [c, d], remove: [a]]
    end
  end
end
