defmodule Purple.Feed do
  @moduledoc """
  Context for managing RSS feeds.
  """
  alias Purple.Feed
  alias Purple.Repo
  # import Ecto.Query

  def parse_rss_feed(url) when is_binary(url) do
    with {:ok, content} <- HTTPoison.get(url),
         {:ok, parsed_rss} <- FastRSS.parse(content.body) do
      {:ok, parsed_rss}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def parse_rss_feed(%Feed.Source{} = source) do
    parse_rss_feed(source.url)
  end

  def create_source(url) do
    with {:ok, rss_feed} <- parse_rss_feed(url),
         {:ok, source} <- Repo.insert(%Feed.Source{url: url, title: Map.get(rss_feed, "title")}) do
      {:ok, source}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def save_items_from_source(%Feed.Source{} = source) do
    {:ok, parsed_rss} = parse_rss_feed(source)

    Enum.each(Map.get(parsed_rss, "items", []), fn item ->
      Repo.insert!(%Feed.Item{
        source_id: source.id,
        title: Map.get(item, "title"),
        link: Map.get(item, "link")
      })
    end)
  end
end
