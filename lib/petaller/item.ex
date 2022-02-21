defmodule Petaller.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :description, :string
    field :priority, :integer, default: 1
    field :completed_at, :naive_datetime
    has_many :entries, Petaller.ItemEntry

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:description, :priority, :completed_at])
    |> validate_required([:description, :priority])
  end
end
