defmodule PurpleWeb.BoardLive.Helpers do
  @moduledoc """
  Helpers for board live views
  """
  use PurpleWeb, :verified_routes

  def search_path(nil, params), do: search_path(params)

  def search_path(board_id, params) when is_map(params) do
    ~p"/board/search#{board_id}?#{params}"
  end

  def search_path(params) when is_map(params) do
    ~p"/board/search?#{params}"
  end

  def search_path(nil) do
    search_path()
  end

  def search_path(board_id) do
    ~p"/board/search#{board_id}"
  end

  def search_path() do
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
        label: "Board",
        to: ~p"/board",
        children:
          Enum.map(
            Purple.Board.list_user_boards(user_id),
            &%{
              group: true,
              label: &1.name,
              to: ~p"/board/#{&1}"
            }
          )
      },
      %{
        label: "Search",
        to: ~p"/board/search"
      },
      %{
        label: "Board settings",
        to: ~p"/board/settings"
      }
    ]
  end
end
