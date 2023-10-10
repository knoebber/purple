defmodule PurpleWeb.WeatherSnapshotController do
  use PurpleWeb, :controller
  require Logger

  alias Purple.KeyValue
  alias Purple.Weather
  alias Purple.Weather.{WeatherSnapshot, Rainfall, Wind}

  @cache_key :last_weather_report
  @snapshot_persist_interval_seconds 1800

  action_fallback PurpleWeb.FallbackController

  defp maybe_save_wind_and_rain(params, last_wind) do
    get_val = fn key -> Map.get(params, key) end
    unix_timestamp = get_val.("unix_timestamp")

    mph = get_val.("wind_speed_mph")
    direction_degrees = get_val.("wind_direction_degrees")

    wind_params =
      if is_nil(last_wind) or abs(mph - last_wind.mph) > 1 or
           abs(direction_degrees - last_wind.direction_degrees) > 1 do
        # Only save rain when it's different than the last reading
        %{
          "mph" => mph,
          "direction_degrees" => direction_degrees,
          "unix_timestamp" => unix_timestamp
        }
      else
        %{}
      end

    # Always save rain if it exists
    rain_params = %{
      "millimeters" => get_val.("rain_millimeters"),
      "unix_timestamp" => unix_timestamp
    }

    wind_changeset = Wind.changeset(wind_params)
    rain_changeset = Rainfall.changeset(rain_params)

    maybe_save = fn changeset, save_fn ->
      if changeset.valid? do
        case save_fn.() do
          {:ok, result} ->
            Logger.info("saved #{inspect(result)}")
            result

          err_tuple ->
            Logger.error("failed to save #{inspect(err_tuple)}")
            nil
        end
      end
    end

    %{
      wind: maybe_save.(wind_changeset, fn -> Weather.save_wind(wind_params) end),
      rain: maybe_save.(rain_changeset, fn -> Weather.save_rainfall(rain_params) end)
    }
  end

  def broadcast(conn, %{"weather_snapshot" => params}) do
    with %Ecto.Changeset{valid?: true} = changeset <-
           Weather.change_weather_snapshot(
             %WeatherSnapshot{},
             params
           ) do
      Phoenix.PubSub.broadcast(
        Purple.PubSub,
        "weather_snapshot",
        {
          :weather_snapshot,
          changeset.changes
          |> Map.drop([:unix_timestamp])
        }
      )

      %{last_snapshot: last_snapshot, last_wind: last_wind} =
        last_weather_report =
        case KeyValue.get(@cache_key) do
          val when is_map(val) -> val
          _ -> %{last_snapshot: nil, last_wind: nil}
        end

      should_save_new_snapshot =
        is_nil(last_snapshot) or
          NaiveDateTime.diff(Purple.Date.utc_now(), last_snapshot.timestamp) >
            @snapshot_persist_interval_seconds

      last_snapshot =
        if should_save_new_snapshot do
          case Weather.create_weather_snapshot(params) do
            {:ok, snapshot} ->
              snapshot

            err_tuple ->
              Logger.error("failed to save #{inspect(err_tuple)}")
              last_snapshot
          end
        else
          last_snapshot
        end

      %{wind: wind} = maybe_save_wind_and_rain(params, last_wind)

      new_weather_report = %{
        last_snapshot: last_snapshot,
        last_wind: wind || last_wind
      }

      if new_weather_report != last_weather_report do
        KeyValue.insert(@cache_key, new_weather_report)
      end

      conn
      |> put_status(:ok)
      |> render(:show, weather_snapshot: changeset)
    else
      changeset ->
        Logger.error("invalid weather snapshot: #{inspect(changeset)}")
        {:error, changeset}
    end
  end
end
