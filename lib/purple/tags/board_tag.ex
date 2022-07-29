defmodule Purple.Tags.BoardTag do
  use Ecto.Schema

  schema "board_tags" do
    belongs_to :board, Purple.Board.UserBoard
    belongs_to :tag, Purple.Tags.Tag

    timestamps(updated_at: false)
  end
end
