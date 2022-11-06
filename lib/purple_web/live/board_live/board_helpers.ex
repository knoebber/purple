defmodule PurpleWeb.BoardLive.BoardHelpers do
  @moduledoc """
  Helpers for board live views
  """

  alias Purple.Board
  alias PurpleWeb.Router.Helpers, as: Routes

  def board_index_path(nil, params) do
    Routes.board_index_path(PurpleWeb.Endpoint, :index, params)
  end

  def board_index_path(id, params) do
    Routes.board_index_path(PurpleWeb.Endpoint, :index, id, params)
  end

  def index_path(id, params) do
    board_index_path(id, Purple.drop_falsey_values(params))
  end

  def index_path(id) do
    board_index_path(id, %{})
  end

  def index_path() do
    board_index_path(nil, %{})
  end

  def board_settings_path do
    Routes.board_board_settings_path(PurpleWeb.Endpoint, :index)
  end

  def item_create_path(params \\ %{})

  def item_create_path(params = %{}) do
    Routes.board_create_item_path(PurpleWeb.Endpoint, :create, params)
  end

  def item_create_path(user_board_id) when is_integer(user_board_id) do
    item_create_path(%{user_board_id: user_board_id})
  end

  def item_create_path(_) do
    item_create_path()
  end

  def show_item_path(item) do
    Routes.board_show_item_path(PurpleWeb.Endpoint, :show, item)
  end

  def assign_side_nav(socket) do
    Phoenix.Component.assign(socket, :side_nav, side_nav(socket.assigns.current_user.id))
  end

  def side_nav(user_id) when is_integer(user_id) do
    [
      %{
        label: "All Items",
        to: index_path(),
        children:
          Enum.map(
            Board.list_user_boards(user_id),
            &%{
              group: true,
              label: &1.name,
              to: index_path(&1.id)
            }
          )
      },
      %{
        label: "Board settings",
        to: board_settings_path()
      }
    ]
  end
end
