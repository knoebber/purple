defmodule PurpleWeb.WeatherSnapshotJSON do
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
    weather_snapshot
  end
end
