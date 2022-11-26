defmodule PurpleWeb.BoardLive.Helpers do
  @moduledoc """
  Helpers for board live views
  """
  use PurpleWeb, :verified_routes

  def board_path(nil, params), do: board_path(params)
  def board_path(board_id, params) when is_map(params) do
    ~p"/board/#{board_id}?#{params}"
  end


  def board_path(params) when is_map(params) do
    ~p"/board?#{params}"
  end

  def board_path(nil) do
    board_path()
  end

  def board_path(board_id) do
    ~p"/board/#{board_id}"
  end

  def board_path() do
    ~p"/board"
  end

  def item_create_path(nil) do
    ~p"/board/item/create"
  end

  def item_create_path(board_id) do
    ~p"/board/item/create?user_board_id=#{board_id}"
  end

  def assign_side_nav(socket) do
    Phoenix.Component.assign(socket, :side_nav, side_nav(socket.assigns.current_user.id))
  end

  def side_nav(user_id) when is_integer(user_id) do
    [
      %{
        label: "All Items",
        to: ~p"/board",
        children:
          Enum.map(
            Purple.Board.list_user_boards(user_id),
            &%{
              group: true,
              label: &1.name,
              to: board_path(&1.id)
            }
          )
      },
      %{
        label: "Board settings",
        to: ~p"/board/settings"
      }
    ]
  end
end
