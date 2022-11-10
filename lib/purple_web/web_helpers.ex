defmodule PurpleWeb.WebHelpers do
  @moduledoc """
  Functions that are available to all purple web views
  """
  alias PurpleWeb.Endpoint
  alias PurpleWeb.Router.Helpers, as: Routes

  def strip_markdown(markdown) do
    Regex.replace(~r/[#`*\n]/, markdown, "")
  end

 def changeset_to_reason_list(%Ecto.Changeset{errors: errors}) do
    Enum.map(
      errors,
      fn {_, {reason, _}} -> reason end
    )
  end

  def text_area_rows(""), do: 3

  def text_area_rows(content) do
    content
    |> String.split("\n")
    |> length()
  end

  def get_tag_link(tag, :board), do: Routes.board_index_path(Endpoint, :index, tag: tag)
  def get_tag_link(tag, :run), do: Routes.run_index_path(Endpoint, :index, tag: tag)
  def get_tag_link(tag, :finance), do: Routes.finance_index_path(Endpoint, :index, tag: tag)
  def get_tag_link(tag, _), do: "?tag=#{tag}"

  def markdown(md, options \\ []) when is_binary(md) and is_list(options) do
    md
    |> Purple.Markdown.markdown_to_html(%{
      checkbox_map: Keyword.get(options, :checkbox_map, %{}),
      get_tag_link: &get_tag_link(&1, Keyword.get(options, :link_type)),
      fancy_link_map: Keyword.get(options, :fancy_link_map, %{})
    })
    |> Phoenix.HTML.raw()
  end

  def get_num_textarea_rows(content) do
    max(3, length(String.split(content, "\n")) + 1)
  end
end
