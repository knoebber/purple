defmodule Purple.Tags.UserBoardTag do
  @moduledoc """
  Associates user boards to tags
  """

  use Ecto.Schema

  schema "user_board_tags" do
    belongs_to :user_board, Purple.Board.UserBoard
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
