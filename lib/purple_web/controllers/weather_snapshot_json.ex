defmodule PurpleWeb.WeatherSnapshotJSON do
  @doc """
  Renders a list of weather_snapshots.
  """
  def index(%{weather_snapshots: weather_snapshots}) do
    %{data: for(weather_snapshot <- weather_snapshots, do: data(weather_snapshot))}
  end

  @doc """
  Renders a single weather_snapshot.
  """
  def show(%{weather_snapshot: weather_snapshot}) do
    %{data: data(weather_snapshot)}
  end

  defp data(%Ecto.Changeset{changes: changes}) do
    data(Map.put(changes, :id, nil))
  end

  defp data(weather_snapshot) when is_map(weather_snapshot) do
    %{
      id: weather_snapshot.id,
      humidity: weather_snapshot.humidity,
      pressure: weather_snapshot.pressure,
      temperature: weather_snapshot.temperature,
      timestamp: weather_snapshot.timestamp
    }
  end
end
