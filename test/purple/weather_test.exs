defmodule Purple.WeatherTest do
  use Purple.DataCase

  alias Purple.Weather

  describe "weather_snapshots" do
    alias Purple.Weather.WeatherSnapshot

    import Purple.WeatherFixtures

    @invalid_attrs %{humidity: nil, pressure: nil, temperature: nil, timestamp: nil}

    test "list_weather_snapshots/0 returns all weather_snapshots" do
      weather_snapshot = weather_snapshot_fixture()
      assert Weather.list_weather_snapshots() == [weather_snapshot]
    end

    test "get_weather_snapshot!/1 returns the weather_snapshot with given id" do
      weather_snapshot = weather_snapshot_fixture()
      assert Weather.get_weather_snapshot!(weather_snapshot.id) == weather_snapshot
    end

    test "create_weather_snapshot/1 with valid data creates a weather_snapshot" do
      valid_attrs = %{humidity: 120.5, pressure: 120.5, temperature: 120.5, timestamp: ~T[14:00:00]}

      assert {:ok, %WeatherSnapshot{} = weather_snapshot} = Weather.create_weather_snapshot(valid_attrs)
      assert weather_snapshot.humidity == 120.5
      assert weather_snapshot.pressure == 120.5
      assert weather_snapshot.temperature == 120.5
      assert weather_snapshot.timestamp == ~T[14:00:00]
    end

    test "create_weather_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Weather.create_weather_snapshot(@invalid_attrs)
    end

    test "update_weather_snapshot/2 with valid data updates the weather_snapshot" do
      weather_snapshot = weather_snapshot_fixture()
      update_attrs = %{humidity: 456.7, pressure: 456.7, temperature: 456.7, timestamp: ~T[15:01:01]}

      assert {:ok, %WeatherSnapshot{} = weather_snapshot} = Weather.update_weather_snapshot(weather_snapshot, update_attrs)
      assert weather_snapshot.humidity == 456.7
      assert weather_snapshot.pressure == 456.7
      assert weather_snapshot.temperature == 456.7
      assert weather_snapshot.timestamp == ~T[15:01:01]
    end

    test "update_weather_snapshot/2 with invalid data returns error changeset" do
      weather_snapshot = weather_snapshot_fixture()
      assert {:error, %Ecto.Changeset{}} = Weather.update_weather_snapshot(weather_snapshot, @invalid_attrs)
      assert weather_snapshot == Weather.get_weather_snapshot!(weather_snapshot.id)
    end

    test "delete_weather_snapshot/1 deletes the weather_snapshot" do
      weather_snapshot = weather_snapshot_fixture()
      assert {:ok, %WeatherSnapshot{}} = Weather.delete_weather_snapshot(weather_snapshot)
      assert_raise Ecto.NoResultsError, fn -> Weather.get_weather_snapshot!(weather_snapshot.id) end
    end

    test "change_weather_snapshot/1 returns a weather_snapshot changeset" do
      weather_snapshot = weather_snapshot_fixture()
      assert %Ecto.Changeset{} = Weather.change_weather_snapshot(weather_snapshot)
    end
  end
end
