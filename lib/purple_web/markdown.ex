defmodule PurpleWeb.Markdown do
  alias Purple.Tags

  def strip_markdown(markdown) do
    Regex.replace(~r/[#`*\n]/, markdown, "")
  end

  def parse_tags(text_leaf) when is_binary(text_leaf) do
    Regex.split(
      Tags.tag_pattern(),
      text_leaf,
      include_captures: true
    )
    |> Enum.map(fn
      <<?#, tagname::binary>> ->
        {"a",
         [
           {"class", "tag"},
           {"href", "/board?tag=#{tagname}"}
         ], [tagname], %{}}

      text ->
        text
    end)
  end

  def map_ast(ast), do: map_ast(ast, false)

  def map_ast(ast, text_is_eligible_for_hashtag) do
    Enum.map(ast, fn
      {"a", _, _, _} = node ->
        Earmark.AstTools.merge_atts_in_node(node, target: "_blank")

      {tag, atts, children, m} ->
        {tag, atts, map_ast(children, tag in Tags.valid_tag_parents()), m}

      text_leaf ->
        if text_is_eligible_for_hashtag, do: parse_tags(text_leaf), else: text_leaf
    end)
  end

  def markdown(md) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} ->
        map_ast(ast)
        |> Earmark.Transform.transform()

      _ ->
        md
    end
  end

  def markdown_to_html(md) do
    markdown(md)
    |> HtmlSanitizeEx.markdown_html()
    |> Phoenix.HTML.raw()
  end
end
