defmodule Petaller.Items.Item do

  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :description, :string
    field :priority, :integer, default: 3
    field :completed_at, :naive_datetime

    timestamps()
  end

  def changeset(item, params) do
    item
    |> cast(params, [:description, :priority, :completed_at])
    |> validate_required([:description, :priority])
  end
end

