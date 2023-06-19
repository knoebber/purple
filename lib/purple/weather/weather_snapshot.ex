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
    field :wind_speed_ms, :float, virtual: true
    field :rain_millimeters, :float, virtual: true
  end

  def put_timestamp(changeset) do
    unix_time = get_field(changeset, :unix_timestamp)

    if is_integer(unix_time) do
      put_change(changeset, :timestamp, Purple.Date.unix_to_naive(unix_time))
    else
      changeset
    end
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
      :wind_speed_ms
    ])
    |> validate_required([:humidity, :pressure, :temperature, :unix_timestamp])
    |> validate_number(:unix_timestamp, greater_than: 1_684_615_665)
    |> put_timestamp()
  end
end
