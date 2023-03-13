defmodule Purple.Tags.Tag do
  import Ecto.Changeset
  use Ecto.Schema

  schema "tags" do
    field :name, :string
    many_to_many :items, Purple.Board.Item, join_through: Purple.Tags.ItemTag

    timestamps(updated_at: false)
  end

  def changeset(%__MODULE__{} = tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[a-z0-9]{2,32}$/)
  end
end
