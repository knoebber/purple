defmodule Purple.MarkdownTest do
  use Purple.DataCase

  import Purple.Markdown

  defp parse_document(html) when is_binary(html) do
    {:ok, doc} = Floki.parse_document(html)
    doc
  end

  defp find_checkboxes(doc) do
    Floki.find(doc, "input[type=\"checkbox\"]")
  end

  defp find_tag_links(doc) do
    Floki.find(doc, "a.tag.internal")
  end

  defp count_rendered_checkboxes(markdown) do
    markdown
    |> markdown_to_html()
    |> parse_document()
    |> find_checkboxes()
    |> length()
  end

  defp count_rendered_tag_links(markdown) do
    markdown
    |> markdown_to_html()
    |> parse_document()
    |> find_tag_links()
    |> length()
  end

  describe "markdown_to_html/2" do
    test "renders checkboxes" do
      assert count_rendered_checkboxes("+ x") == 0
      assert count_rendered_checkboxes("+ x ") == 0
      assert count_rendered_checkboxes("+ x task") == 1
      assert count_rendered_checkboxes("+ x task x ") == 1
      assert count_rendered_checkboxes("- x task\n- x task2\n- x task3") == 3
      assert count_rendered_checkboxes("1. x task\n1. x task2\n1. x 👍\n1. x 4") == 4

      html =
        markdown_to_html(
          "- x task\n- x task2 \n- x 👍 ",
          %{
            checkbox_map: %{
              "task" => %{id: 1, is_done: false},
              "task2" => %{id: 2, is_done: true},
              "👍" => %{id: 3, is_done: true}
            }
          }
        )

      expected_html = ~s"""
      <ul>
        <li>
          <span>
            <input type="checkbox" phx-click="toggle-checkbox" phx-value-id="1">
            task
          </span>
        </li>
        <li>
          <span>
            <input checked="checked" type="checkbox" phx-click="toggle-checkbox" phx-value-id="2">
            task2
          </span>
        </li>
        <li>
          <span>
            <input checked="checked" type="checkbox" phx-click="toggle-checkbox" phx-value-id="3">
            👍
          </span>
        </li>
      </ul>
      """

      assert String.replace(html, ~r/\s/, "") == String.replace(expected_html, ~r/\s/, "")
    end

    test "renders tag links" do
      assert count_rendered_tag_links("`#tag`") == 0
      assert count_rendered_tag_links("**#tag**") == 0
      assert count_rendered_tag_links("#tag") == 1
      assert count_rendered_tag_links("+ #tag\n+ #tag") == 2
    end

    test "renders tag links and checkboxes" do
      doc =
        ~s"""
        # header #tag1 x 

        + x checkbox1 #tag2
        + x checkbox2
        + x checkbox3 #tag3

        ```
        whatever #notag
        ```

        - x checkbox4

        #tag4
        """
        |> markdown_to_html
        |> parse_document

      assert length(find_checkboxes(doc)) == 4
      assert length(find_tag_links(doc)) == 4
    end
  end

  describe "markdown to lists" do
    test "returns expected html" do
      checkbox_map = %{
        "task" => %{id: 1, is_done: false},
        "task2" => %{id: 2, is_done: true},
        "task3" => %{id: 3, is_done: true}
      }

      markdown = ~s"""
      # header that is ignored
      - x task #tag1
      - not checkbox 1
      - x task2
      - not checkbox **2**
      - x task3

      ## header that is ignored

      whatever **content**.

      1. x task4
      1. not checkbox 3 #tag1
      """

      checkbox_html = markdown_to_checkbox_list(markdown, %{checkbox_map: checkbox_map})

      expected_html = ~s"""
      <ul>
        <li>
          <span>
            <input type="checkbox" phx-click="toggle-checkbox" phx-value-id="1"/>
            task
          </span>
      <a class="internal tag" href="/?tag=tag1">#tag1</a>
        </li>
        <li>
          <span>
            <input checked="checked" type="checkbox" phx-click="toggle-checkbox" phx-value-id="2"/>
            task2
          </span>
        </li>
        <li>
          <span>
            <input checked="checked" type="checkbox" phx-click="toggle-checkbox" phx-value-id="3"/>
            task3
          </span>
        </li>
        <li>
          <span>
            <input type="checkbox"/>
            task4
          </span>
        </li>
      </ul>
      """

      assert String.replace(checkbox_html, ~r/\s/, "") ==
               String.replace(expected_html, ~r/\s/, "")

      not_checkbox_html = markdown_to_non_checkbox_list(markdown, %{checkbox_map: checkbox_map})

      expected_html = ~s"""
      <ul>
        <li>
      not checkbox 1
        </li>
        <li>
          not checkbox <strong>2</strong>
        </li>
        <li>
          not checkbox 3 <a class="internal tag" href="/?tag=tag1">#tag1</a>
        </li>
      </ul>
      """

      assert String.replace(not_checkbox_html, ~r/\s/, "") ==
               String.replace(expected_html, ~r/\s/, "")
    end
  end

  describe "extract_checkbox_content/1" do
    test "finds expected checkbox lists" do
      assert extract_checkbox_content("+ x") == []
      assert extract_checkbox_content("+ x ") == []
      assert extract_checkbox_content("+ x task") == ["task"]
      assert extract_checkbox_content("+ x task x ") == ["task x"]

      assert extract_checkbox_content("- x task\n- x task2\n- x task3") == [
               "task3",
               "task2",
               "task"
             ]

      assert extract_checkbox_content("1. x task\n1. x task two \n1. x 👍\n1. x 4 ") == [
               "4",
               "👍",
               "task two",
               "task"
             ]

      assert extract_checkbox_content(~s"""
             # header #tag1 x 

             + x checkbox1 #tag2
             + x checkbox2
             + x checkbox3 #tag3

             ```
             whatever #notag
             ```
             - x checkbox4

             #tag4
             """) == [
               "checkbox4",
               "checkbox3 #tag3",
               "checkbox2",
               "checkbox1 #tag2"
             ]
    end
  end
end
