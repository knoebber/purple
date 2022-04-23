defmodule Purple.Tags.Tag do
  alias Purple.Tags.Tag

  use Ecto.Schema

  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :items, Purple.Board.Item, join_through: Purple.Tags.ItemTag
    many_to_many :runs, Purple.Activities.Run, join_through: Purple.Tags.RunTag
    timestamps(updated_at: false)
  end

  def changeset(attrs) do
    %Tag{}
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-z0-9]{2,32}$/)
  end
end
