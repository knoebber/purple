defmodule Purple.Board.UserBoard do
  @moduledoc """
  Schema for boards - lets users save filters for viewing items.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "user_boards" do
    field :name, :string, default: ""
    field :is_default, :boolean, default: false
    field :show_done, :boolean, default: false

    timestamps()

    belongs_to :user, Purple.Accounts.User
    many_to_many :tags, Purple.Tags.Tag, join_through: Purple.Tags.UserBoardTag
  end

  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :is_default, :show_done])
    |> validate_required([:name])
  end
end
