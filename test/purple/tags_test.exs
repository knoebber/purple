defmodule Purple.TagsTest do
  use Purple.DataCase

  alias Purple.Tags
  alias Purple.Tags.Tag
  alias Purple.Board.Item
  alias Purple.Board.ItemEntry

  describe "tags" do
    test "extract_tags_from_markdown\1" do
      assert Tags.extract_tags_from_markdown("#invalid\n```") == []

      result =
        Tags.extract_tags_from_markdown(~s"""
        # header #header1

        * #list1
        * #list2
        * 3

        ```
        code #code is a comment not a tag
        ```

        `also invalid #inlinecode`

        https://example.com#linkanchor

        normal #paragraph hashtag
        ---
        * https://github.com/knoebber/nicolasknoebber.com/commit/7ffba4a96283a30a2d4ba91243814ce8dbb5a2a6
        * https://runsignup.com/Race/Results/110531?rsus=100-200-bb2f0d15-6ebe-4ce9-b695-5a9efb2a5891#resultSetId-263870;perpage:100
        """)
        |> Enum.sort()

      assert result == [
               "header1",
               "list1",
               "list2",
               "paragraph"
             ]
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

      assert Tags.extract_tags(%Item{entries: [], description: ""}) == []
      assert Tags.extract_tags(%Item{description: "#Purple", entries: []}) == ["purple"]

      assert Tags.extract_tags(%Item{
               description: "#Purple",
               entries: [
                 %ItemEntry{content: "#wee\n#TAG \n #COOL `#code`"},
                 %ItemEntry{content: "#tag2\n\n```\nok#whatever\n```\n #tag3\n#purple\n#tag4"}
               ]
             }) == ["purple", "wee", "tag", "cool", "tag3", "tag4", "tag2"]
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
