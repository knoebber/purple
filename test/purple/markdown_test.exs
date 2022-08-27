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
end
