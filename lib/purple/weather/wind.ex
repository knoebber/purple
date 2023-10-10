defmodule Purple.Weather.Wind do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wind" do
    field :mph, :float
    field :direction_degrees, :integer
    field :timestamp, :naive_datetime

    field :unix_timestamp, :integer, virtual: true
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:mph, :direction_degrees, :unix_timestamp])
    |> validate_required([:mph, :direction_degrees, :unix_timestamp])
    |> validate_number(:mph, greater_than: 0)
    |> validate_number(:direction_degrees, greater_than: 0)
    |> Purple.Weather.Helpers.put_timestamp()
  end
end
