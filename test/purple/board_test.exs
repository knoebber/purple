defmodule Purple.BoardTest do
  use Purple.DataCase

  import Purple.Board

  defp make_checkboxes(content) do
    Enum.sort(extract_checkboxes(%Purple.Board.ItemEntry{content: content}))
  end

  describe "extract_checkboxes/1" do
    test "checkbox content is expected" do
      assert make_checkboxes("+ x") == []
      assert make_checkboxes("+ x ") == []
      assert make_checkboxes("+ x task") == ["task"]
      assert make_checkboxes("+ x task x ") == ["task x "]
      assert make_checkboxes("- x task\n- x task2\n- x task3") == ["task", "task2", "task3"]

      assert make_checkboxes("1. x task\n1. x task2\n1. x 👍\n1. x 4") == [
               "4",
               "task",
               "task2",
               "👍",
             ]

      assert make_checkboxes(~s"""
             # header #tag1 x 

             + x checkbox1 #tag2
             + x checkbox2
             + x checkbox3 #tag3

             ```
             whatever #notag
             ```

             - x checkbox4

             #tag4
             """) == ["checkbox1 #tag2", "checkbox2", "checkbox3 #tag3", "checkbox4"]
    end
  end
end
