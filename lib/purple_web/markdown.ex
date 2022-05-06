defmodule PurpleWeb.Markdown do
  alias PurpleWeb.Router.Helpers, as: Routes
  alias PurpleWeb.Endpoint
  alias Purple.Tags

  def get_link(tag, :board), do: Routes.board_index_path(Endpoint, :index, tag: tag)
  def get_link(tag, :run), do: Routes.run_index_path(Endpoint, :index, tag: tag)
  def get_link(tag, _), do: "?tag=#{tag}"

  def strip_markdown(markdown) do
    Regex.replace(~r/[#`*\n]/, markdown, "")
  end

  def parse_tags(text_leaf, link_type) when is_binary(text_leaf) do
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
           {"href", get_link(tagname, link_type)},
         ], [tagname], %{}}

      text ->
        text
    end)
  end

  def map_ast(ast, link_type, text_is_eligible_for_hashtag \\ false) do
    Enum.map(ast, fn
      {"a", _, _, _} = node ->
        Earmark.AstTools.merge_atts_in_node(node, target: "_blank")

      {"h1", atts, children, m} ->
        {"h2", atts, children, m}

      {"h2", atts, children, m} ->
        {"h3", atts, children, m}

      {"h3", atts, children, m} ->
        {"h4", atts, children, m}

      {tag, atts, children, m} ->
        {tag, atts, map_ast(children, link_type, tag in Tags.valid_tag_parents()), m}

      text_leaf when text_is_eligible_for_hashtag ->
        parse_tags(text_leaf, link_type)

      text_leaf ->
        text_leaf
    end)
  end

  def markdown(md, link_type) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} ->
        map_ast(ast, link_type) |> Earmark.Transform.transform()

      _ ->
        md
    end
  end

  def markdown_to_html(md, link_type) do
    markdown(md, link_type) |> Phoenix.HTML.raw()
  end
end
