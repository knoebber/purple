defmodule PurpleWeb.FancyLink do
  alias Purple.KeyValue

  @callback get_fancy_link_type() :: String.t()
  @callback get_fancy_link_title(Map.t()) :: String.t() | nil

  defp implemented_by?(module) do
    module.module_info()[:attributes]
    |> Keyword.get_values(:behaviour)
    |> Enum.any?(&(&1 == [PurpleWeb.FancyLink]))
  end

  def extract_routes_from_markdown(md) do
    "(^|\\s)(https?://#{PurpleWeb.WebHelpers.host()}[^/]*)(/\\S+)"
    |> Regex.compile!()
    |> Regex.scan(md)
    |> Enum.map(fn [_, _, basename, path] -> {basename, path} end)
  end

  @doc """
  iex> build_route_tuple({"http://localhost:4000", "/board/item/1?a=2"})
  {
    "http://localhost:4000/board/item/1?a=2",
     PurpleWeb.BoardLive.ShowItem,
     %{"a" => "2", "id" => "1"}
  }

  iex> build_route_tuple("http://localhost:4000/board/item/100")
  {
    "http://localhost:4000/board/item/100",
     PurpleWeb.BoardLive.ShowItem,
     %{"id" => "100"}
  }

  iex> build_route_tuple("localhost:4000/board")
  nil

  iex> build_route_tuple("example.com")
  nil
  """
  def build_route_tuple({basename, path}) do
    case Phoenix.Router.route_info(PurpleWeb.Router, "GET", path, PurpleWeb.WebHelpers.host()) do
      %{phoenix_live_view: {module, _, _, _}, path_params: path_params} ->
        {
          basename <> path,
          module,
          expand_path_params(path_params)
        }

      _ ->
        nil
    end
  end

  def build_route_tuple(absolute_url) when is_binary(absolute_url) do
    index =
      absolute_url
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.find_index(fn {g, index} ->
        # ensure forward slashes after http(s) are skipped
        if index > 8 do
          g == "/"
        end
      end)

    if not is_nil(index) do
      {basename, path} = String.split_at(absolute_url, index)

      basename_pattern = Regex.compile!("^https?://#{PurpleWeb.WebHelpers.host()}")

      if Regex.match?(basename_pattern, basename) and String.starts_with?(path, "/") do
        build_route_tuple({basename, path})
      end
    end
  end

  defp expand_path_params(params) when is_map(params) do
    Enum.reduce(
      Map.keys(params),
      %{},
      fn key, result ->
        val = params[key]
        parts = String.split(val, "?")
        first_param = Enum.at(parts, 0)
        query_string = Enum.at(parts, 1, "")

        result
        |> Map.put(key, first_param)
        |> Map.merge(URI.decode_query(query_string))
      end
    )
  end

  def build_fancy_link_groups(urls) when is_list(urls) do
    Enum.reduce(
      urls,
      %{},
      fn url, fancy_link_groups ->
        {url, module, _} = route_tuple = build_route_tuple(url)
        title = get_fancy_link_title(route_tuple)

        if title do
          type = module.get_fancy_link_type()
          group = Map.get(fancy_link_groups, type, [])
          Map.put(fancy_link_groups, type, [{url, title} | group])
        else
          fancy_link_groups
        end
      end
    )
  end

  def get_fancy_link_title({url, module, params}) when is_atom(module) and is_map(params) do
    unix_now = Purple.Date.unix_now()
    seconds_until_stale = 3600

    if implemented_by?(module) do
      cache_key = "fancy_link:#{url}"

      case KeyValue.get(cache_key) do
        nil ->
          title = module.get_fancy_link_title(params)
          KeyValue.insert(cache_key, {title, unix_now})
          title

        {cached_title, inserted_at} ->
          if unix_now - inserted_at > seconds_until_stale do
            KeyValue.delete(cache_key)
          end

          cached_title
      end
    end
  end

  defp get_formatted_fancy_link_type_and_title({_, module, _} = route_tuple) do
    title = get_fancy_link_title(route_tuple)

    if title do
      Enum.join([module.get_fancy_link_type(), title], " · ")
    end
  end

  def build_fancy_link_map(markdown) when is_binary(markdown) do
    markdown
    |> extract_routes_from_markdown()
    |> Enum.reduce(
      %{},
      fn absolute_url, fancy_link_map ->
        with {url, _, _} = route_tuple <- build_route_tuple(absolute_url),
             formatted_title when is_binary(formatted_title) <-
               get_formatted_fancy_link_type_and_title(route_tuple) do
          Map.put(fancy_link_map, url, formatted_title)
        else
          _ -> fancy_link_map
        end
      end
    )
  end
end
