defmodule PurpleWeb.WeatherSnapshotController do
  use PurpleWeb, :controller

  alias Purple.Weather
  alias Purple.Weather.WeatherSnapshot

  action_fallback PurpleWeb.FallbackController

  defp get_params(%{"weather_snapshot" => ws}) do
    ws
  end

  # def create(conn, params) do
  #   with {:ok, %WeatherSnapshot{} = weather_snapshot} <-
  #          Weather.create_weather_snapshot(get_params(params)) do
  #     conn
  #     |> put_status(:created)
  #     |> render(:show, weather_snapshot: weather_snapshot)
  #   end
  # end

  def broadcast(conn, params) do
    with %Ecto.Changeset{valid?: true} = changeset <-
           Weather.change_weather_snapshot(%WeatherSnapshot{}, get_params(params)) do
      Phoenix.PubSub.broadcast(
        Purple.PubSub,
        "weather_snapshot",
        {:weather_snapshot, Map.drop(changeset.changes, [:unix_timestamp])}
      )

      conn
      |> put_status(:ok)
      |> render(:show, weather_snapshot: changeset)
    else
      changeset -> {:error, changeset}
    end
  end
end
