defmodule Purple.Markdown do
  @moduledoc """
  Functions for parsing and manipulating markdown
  """
  @valid_tag_parents ["p", "li", "h1", "h2", "h3", "h4"]

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

  def render_tag_links(text_leaf, get_link) when is_binary(text_leaf) do
    Enum.map(
      Regex.split(
        Purple.Tags.tag_pattern(),
        text_leaf,
        include_captures: true
      ),
      fn
        <<?#, tagname::binary>> ->
          {"a",
           [
             {"class", "tag"},
             {"href", get_link.(tagname)}
           ], ["#" <> tagname], %{}}

        text ->
          text
      end
    )
  end

  def render_checkboxes(text_leaf) when is_binary(text_leaf) do
    Enum.map(
      Regex.split(
        ~r/ x /,
        text_leaf,
        include_captures: true
      ),
      fn
        " x " ->
          {"input",
           [
             {"type", "checkbox"},
             {"class", "markdown-checkbox"}
           ], [], %{}}

        text ->
          text
      end
    )
  end

  def make_link(node) do
    case Earmark.AstTools.find_att_in_node(node, "href") do
      <<?/, _::binary>> ->
        Earmark.AstTools.merge_atts_in_node(node, class: "internal")

      _ ->
        Earmark.AstTools.merge_atts_in_node(node, class: "external", target: "_blank")
    end
  end

  def get_valid_extensions(html_tag \\ "") do
    %{
      checkbox: html_tag == "li",
      tag_link: html_tag in @valid_tag_parents
    }
  end

  @doc """
  Transforms a default earmark ast into a custom purple ast.
  """
  def map_purple_ast(ast, get_tag_link, valid_extensions) do
    Enum.map(ast, fn
      {"a", _, _, _} = node ->
        make_link(node)

      {"h1", atts, children, m} ->
        {"h2", atts, map_purple_ast(children, get_tag_link, get_valid_extensions("h2")), m}

      {"h2", atts, children, m} ->
        {"h3", atts, map_purple_ast(children, get_tag_link, get_valid_extensions("h3")), m}

      {"h3", atts, children, m} ->
        {"h4", atts, map_purple_ast(children, get_tag_link, get_valid_extensions("h4")), m}

      {html_tag, atts, children, m} ->
        {
          html_tag,
          atts,
          map_purple_ast(children, get_tag_link, get_valid_extensions(html_tag)),
          m
        }

      text_leaf when is_binary(text_leaf) ->
        case valid_extensions do
          %{tag_link: true} ->
            map_purple_ast(
              render_tag_links(text_leaf, get_tag_link),
              get_tag_link,
              Map.put(valid_extensions, :tag_link, false)
            )

          %{checkbox: true} ->
            map_purple_ast(
              render_checkboxes(text_leaf),
              get_tag_link,
              Map.put(valid_extensions, :checkbox, false)
            )

          _ ->
            text_leaf
        end
    end)
  end

  def markdown_to_html(md, get_tag_link) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} ->
        Earmark.Transform.transform(
          map_purple_ast(
            ast,
            get_tag_link,
            get_valid_extensions()
          )
        )

      _ ->
        md
    end
  end
end
