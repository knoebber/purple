defmodule Purple.Weather.WeatherSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weather_snapshots" do
    field :humidity, :float
    field :pressure, :float
    field :temperature, :float
    field :timestamp, :naive_datetime

    field :unix_timestamp, :integer, virtual: true
    field :wind_direction_degrees, :integer, virtual: true
    field :wind_speed_mph, :float, virtual: true
    field :rain_millimeters, :float, virtual: true
  end

  def changeset(weather_snapshot, attrs) do
    weather_snapshot
    |> cast(attrs, [
      :humidity,
      :pressure,
      :rain_millimeters,
      :temperature,
      :unix_timestamp,
      :wind_direction_degrees,
      :wind_speed_mph
    ])
    |> validate_required([:humidity, :pressure, :temperature, :unix_timestamp])
    |> Purple.Weather.Helpers.put_timestamp()
  end
end
