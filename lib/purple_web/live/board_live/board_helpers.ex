defmodule PurpleWeb.BoardLive.BoardHelpers do
  alias Purple.Board
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

  def user_board_path(id) do
    Routes.board_index_path(PurpleWeb.Endpoint, :index, id)
  end

  def board_settings_path do
    Routes.board_board_settings_path(PurpleWeb.Endpoint, :index)
  end

  def assign_side_nav(socket) do
    Phoenix.LiveView.assign(socket, :side_nav, side_nav(socket.assigns.current_user.id))
  end

  def side_nav(user_id) when is_integer(user_id) do
    user_boards =
      Enum.map(
        Board.list_user_boards(user_id),
        fn ub -> %{label: ub.name, to: user_board_path(ub.id)} end
      ) ++
        [
          %{
            label: "Board settings",
            to: board_settings_path()
          }
        ]
  end
end
