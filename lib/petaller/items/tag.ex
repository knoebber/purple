defmodule Petaller.Items.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :items, Petaller.Items.Item, join_through: Petaller.Items.ItemTag
    timestamps()
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
