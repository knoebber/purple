defmodule PurpleWeb.FancyLink do
  @callback get_fancy_link_type() :: String.t()
  @callback get_fancy_link_title(Map.t()) :: String.t() | nil

  defp host, do: Application.get_env(:purple, PurpleWeb.Endpoint)[:url][:host]

  def implemented_by?(module) do
    module.module_info()[:attributes]
    |> Keyword.get_values(:behaviour)
    |> Enum.any?(&(&1 == [PurpleWeb.FancyLink]))
  end

  def extract_routes_from_markdown(md) do
    "(^|\\s)(https?://#{host()}[^/]*)(/\\S+)"
    |> Regex.compile!()
    |> Regex.scan(md)
    |> Enum.map(fn [_, _, basename, path] -> {basename, path} end)
    |> build_route_tuples()
  end

  def build_route_tuples(basename_path_pairs) when is_list(basename_path_pairs) do
    basename_path_pairs
    |> Enum.map(&build_route_tuple/1)
    |> Enum.filter(& &1)
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
    case Phoenix.Router.route_info(PurpleWeb.Router, "GET", path, host()) do
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

    unless is_nil(index) do
      {basename, path} = String.split_at(absolute_url, index)

      basename_pattern = Regex.compile!("^https?://#{host()}")

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

  def get_fancy_link_title(module, params) when is_atom(module) and is_map(params) do
    if __MODULE__.implemented_by?(module) do
      title = module.get_fancy_link_title(params)

      if title do
        Enum.join([module.get_fancy_link_type(), title], " · ")
      end
    end
  end

  def build_fancy_link_map(route_tuples) when is_list(route_tuples) do
    Enum.reduce(
      route_tuples,
      %{},
      fn {url, module, params}, fancy_link_map ->
        title = get_fancy_link_title(module, params)

        if title do
          Map.put(fancy_link_map, url, title)
        else
          fancy_link_map
        end
      end
    )
  end
end
