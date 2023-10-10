defmodule Purple.Weather.Rainfall do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rainfall" do
    field :millimeters, :float
    field :timestamp, :naive_datetime

    field :unix_timestamp, :integer, virtual: true
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:millimeters, :unix_timestamp])
    |> validate_required([:millimeters, :unix_timestamp])
    |> validate_number(:millimeters, greater_than: 0)
    |> Purple.Weather.Helpers.put_timestamp()
  end
end
