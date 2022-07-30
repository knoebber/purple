defmodule PurpleWeb.BoardLive.BoardHelpers do
  alias PurpleWeb.Router.Helpers, as: Routes

  @moduledoc """
  Helpers for board live views
  """

  @reserved_keys [
    "action",
    "id"
  ]

  def index_path(params, new_params = %{}) do
    Routes.board_index_path(
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

  def board_settings_path do
    Routes.board_board_settings_path(PurpleWeb.Endpoint, :index)
  end

  def side_nav(user_id) when is_integer(user_id) do
    [
      %{
        label: "Board",
        to: index_path()
      },
      %{
        label: "New Item",
        to: index_path(%{}, :new_item)
      },
      %{
        label: "Board settings",
        to: board_settings_path()
      }
    ]
  end
end
