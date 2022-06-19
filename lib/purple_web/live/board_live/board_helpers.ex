defmodule PurpleWeb.BoardLive.BoardHelpers do
  @reserved_keys [
    "action",
    "id"
  ]

  def index_path(params, new_params = %{}) do
    PurpleWeb.Router.Helpers.board_index_path(
      PurpleWeb.Endpoint,
      :index,
      Map.merge(params, new_params)
    )
  end

  def index_path(params, action = :new_item) do
    index_path(params, %{action: action})
  end

  def index_path(params, action = :edit_item, item_id) do
    index_path(params, %{action: action, id: item_id})
  end

  def index_path(params) do
    index_path(
      Map.reject(
        params,
        fn {key, val} -> key in @reserved_keys or val == "" end
      ),
      %{}
    )
  end

  def index_path do
    index_path(%{}, %{})
  end

  def side_nav do
    [
      %{
        label: "Board",
        to: index_path()
      },
      %{
        label: "New Item",
        to: index_path(%{}, :new_item)
      }
    ]
  end
end
