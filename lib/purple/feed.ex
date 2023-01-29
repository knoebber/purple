defmodule Purple.Feed do
  @moduledoc """
  Context for managing RSS feeds.
  """
  alias Purple.Feed
  alias Purple.Repo
  import Ecto.Query
  require Logger

  def parse_pub_date(nil), do: {:error, "pub date is nil"}

  def parse_pub_date(pub_date) when is_binary(pub_date) do
    datetime =
      Enum.find_value(
        ["{RFC1123}"],
        fn format ->
          case Timex.parse(pub_date, format) do
            {:ok, datetime} -> datetime
            _ -> nil
          end
        end
      )

    if datetime do
      if Timex.before?(datetime, Timex.shift(Timex.today, days: -3)) do 
        {:error, :stale}
      else
        {:ok, datetime}
      end
    else
      {:error, "failed to parse pub date [#{pub_date}]"}
    end
  end

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

  def make_item(source_id, item_map) when is_map(item_map) do
    case parse_pub_date(Map.get(item_map, "pub_date")) do
      {:ok, datetime} ->
        {:ok,
         %Feed.Item{
           source_id: source_id,
           title: Map.get(item_map, "title"),
           link: Map.get(item_map, "link"),
           pub_date: Purple.Date.to_naive_datetime(datetime)
         }}

      error ->
        error
    end
  end

  def save_items_from_source(%Feed.Source{} = source) do
    link_map =
      Enum.reduce(
        list_items(%{source_id: source.id}),
        %{},
        fn item, acc ->
          Map.put(acc, item.link, True)
        end
      )

    case parse_rss_feed(source) do
      {:ok, parsed_rss} ->
        Map.get(parsed_rss, "items", [])
        |> Enum.reject(fn item_map -> Map.get(link_map, Map.get(item_map, "link")) end)
        |> Enum.each(fn item_map ->
          with {:ok, item_struct} <- make_item(source.id, item_map),
               {:ok, item_record} <- Repo.insert(item_struct) do
            Logger.info("inserted rss item record #{inspect(item_record)}")
          else
            {:error, :stale} ->
            Logger.info(
                "skipping [#{Map.get(item_map, "link")}]: stale"
              )
            {:error, reason} ->
              Logger.error(
                "failed to create rss item for [#{source.url}] from #{inspect(item_map)}: [#{reason}]"
              )
          end
        end)

      {:error, reason} ->
        Logger.error("failed to parse feed for #{source.url}: #{reason}")
    end
  end

  def create_source(url) do
    with {:ok, rss_feed} <- parse_rss_feed(url),
         {:ok, source} <- Repo.insert(%Feed.Source{url: url, title: Map.get(rss_feed, "title")}) do
      {:ok, source}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp source_filter(query, %{source_id: source_id}) do
    where(query, [item], item.source_id == ^source_id)
  end

  defp source_filter(query, _), do: query

  def list_sources() do 
    Repo.all(Feed.Source)
  end

  def list_items(filter \\ %{}) do
    Feed.Item
    |> join(:inner, [item], source in assoc(item, :source))
    |> source_filter(filter)
    |> order_by([item, _], [desc: item.pub_date])
    |> preload([_, source], source: source)
    |> Repo.paginate(filter)
  end
end
