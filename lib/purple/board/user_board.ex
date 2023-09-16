defmodule Purple.Board.UserBoard do
  @moduledoc """
  Schema for boards - lets users save filters for viewing items.
  """

  alias Purple.Repo
  import Ecto.Changeset
  import Ecto.Query
  use Ecto.Schema

  schema "user_boards" do
    field :name, :string, default: ""
    field :show_done, :boolean, default: false
    field :sort_order_json, :string, default: "{}"

    timestamps()

    belongs_to :user, Purple.Accounts.User

    many_to_many :tags, Purple.Tags.Tag,
      join_through: Purple.Tags.UserBoardTag,
      on_replace: :delete,
      unique: true
  end

  def get_sort_order_map(%__MODULE__{} = ub) do
    Jason.decode!(ub.sort_order_json)
  end

  def get_num_sorted_items(%__MODULE__{} = ub) do
    get_sort_order_map(ub)
    |> Map.values()
    |> Enum.reduce(
      0,
      fn
        lst, total when is_list(lst) ->
          length(lst) + total

        _, total ->
          total
      end
    )
  end

  def changeset(board, %{"tags" => tags} = attrs) do
    changeset =
      board
      |> cast(attrs, [:name, :show_done])
      |> validate_required([:name])

    tag_ids = Enum.map(tags, & &1.id)

    if tags == [] or Repo.exists?(where(Purple.Tags.Tag, [t], t.id in ^tag_ids)) do
      put_assoc(changeset, :tags, tags)
    else
      add_error(changeset, :tags, "tags must already exist")
    end
  end
end
