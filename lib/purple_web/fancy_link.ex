defmodule PurpleWeb.FancyLink do
  @callback get_fancy_link_type() :: String.t()
  @callback get_fancy_link_title(Map.t()) :: String.t() | nil

  def implemented_by?(module) do
    module.module_info()[:attributes]
    |> Keyword.get_values(:behaviour)
    |> Enum.any?(&(&1 == [PurpleWeb.FancyLink]))
  end

  def extract_routes_from_markdown(md) do
    host = Application.get_env(:purple, PurpleWeb.Endpoint)[:url][:host]

    "(^|\\s)(https?://#{host}[^/]*)(/\\S+)"
    |> Regex.compile!()
    |> Regex.scan(md)
    |> Enum.map(fn [_, _, basename, path] ->
      case Phoenix.Router.route_info(PurpleWeb.Router, "GET", path, host) do
        %{phoenix_live_view: {module, _, _, _}, path_params: params} ->
          {
            basename <> path,
            module,
            params
          }

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  def build_fancy_link_map(routes_from_markdown) when is_list(routes_from_markdown) do
    Enum.reduce(
      routes_from_markdown,
      %{},
      fn {url, module, params}, fancy_link_map ->
        if __MODULE__.implemented_by?(module) do
          Map.put(
            fancy_link_map,
            url,
            "🌻 · " <> module.get_fancy_link_type() <> " · " <> module.get_fancy_link_title(params)
          )
        else
          fancy_link_map
        end
      end
    )
  end
end
