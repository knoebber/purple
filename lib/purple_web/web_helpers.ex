defmodule PurpleWeb.WebHelpers do
  @moduledoc """
  Functions that are available to all purple web views
  """
  def make_full_url(path) when is_binary(path) do
    host = Application.get_env(:purple, PurpleWeb.Endpoint)[:url][:host]

    base =
      if Application.get_env(:purple, :env) == :dev do
        "http://#{host}:#{Application.get_env(:purple, PurpleWeb.Endpoint)[:http][:port]}"
      else
        "https://#{host}"
      end

    base <> path
  end

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

  def get_num_textarea_rows(content) do
    max(8, length(String.split(content, "\n")) + 1)
  end

  def assign_fancy_link_map(socket, content) when is_binary(content) do
    Phoenix.Component.assign(
      socket,
      :fancy_link_map,
      content
      |> PurpleWeb.FancyLink.extract_routes_from_markdown()
      |> PurpleWeb.FancyLink.build_fancy_link_map()
    )
  end
end
