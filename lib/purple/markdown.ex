defmodule Purple.Markdown do
  @moduledoc """
  Functions for parsing and manipulating markdown
  """
  @valid_tag_parents ["p", "li", "h1", "h2", "h3"]

  def extract_eligible_tag_text_from_ast(ast) when is_list(ast) do
    {_, result} =
      Earmark.Transform.map_ast_with(
        ast,
        [],
        fn
          {tag, _, children, _} = node, result when tag in @valid_tag_parents ->
            {
              node,
              Enum.reduce(children, result, fn
                text_leaf, acc when is_binary(text_leaf) -> [text_leaf] ++ acc
                _, acc -> acc
              end)
            }

          node, result ->
            {node, result}
        end,
        true
      )

    result
  end

  def extract_eligible_tag_text_from_markdown(md) when is_binary(md) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} -> extract_eligible_tag_text_from_ast(ast)
      _ -> []
    end
  end

  def transform_tags(text_leaf, get_link) when is_binary(text_leaf) do
    Regex.split(
      Purple.Tags.tag_pattern(),
      text_leaf,
      include_captures: true
    )
    |> Enum.map(fn
      <<?#, tagname::binary>> ->
        {"a",
         [
           {"class", "tag internal-link"},
           {"href", get_link.(tagname)}
         ], ["#" <> tagname], %{}}

      text ->
        text
    end)
  end

  def make_link(node) do
    case Earmark.AstTools.find_att_in_node(node, "href") do
      <<?/, _::binary>> ->
        Earmark.AstTools.merge_atts_in_node(node, class: "internal-link")

      _ ->
        Earmark.AstTools.merge_atts_in_node(node, class: "external-link", target: "_blank")
    end
  end

  @doc """
  Transforms a default earmark ast into a custom purple ast.
  """
  def make_purple_ast(ast, get_tag_link, text_is_eligible_for_hashtag \\ false) do
    Enum.map(ast, fn
      {"a", _, _, _} = node ->
        make_link(node)

      {"h1" = tag, atts, children, m} ->
        {"h2", atts, make_purple_ast(children, get_tag_link, tag in @valid_tag_parents), m}

      {"h2" = tag, atts, children, m} ->
        {"h3", atts, make_purple_ast(children, get_tag_link, tag in @valid_tag_parents), m}

      {"h3" = tag, atts, children, m} ->
        {"h4", atts, make_purple_ast(children, get_tag_link, tag in @valid_tag_parents), m}

      {tag, atts, children, m} ->
        {tag, atts, make_purple_ast(children, get_tag_link, tag in @valid_tag_parents), m}

      text_leaf when text_is_eligible_for_hashtag ->
        transform_tags(text_leaf, get_tag_link)

      text_leaf ->
        text_leaf
    end)
  end

  def markdown_to_html(md, get_tag_link) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} ->
        make_purple_ast(ast, get_tag_link) |> Earmark.Transform.transform()

      _ ->
        md
    end
  end
end
