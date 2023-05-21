defmodule Purple.WeatherFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Purple.Weather` context.
  """

  @doc """
  Generate a weather_snapshot.
  """
  def weather_snapshot_fixture(attrs \\ %{}) do
    {:ok, weather_snapshot} =
      attrs
      |> Enum.into(%{
        humidity: 120.5,
        pressure: 120.5,
        temperature: 120.5,
        timestamp: ~T[14:00:00]
      })
      |> Purple.Weather.create_weather_snapshot()

    weather_snapshot
  end
end
