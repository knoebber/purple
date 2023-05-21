defmodule PurpleWeb.WeatherSnapshotControllerTest do
  use PurpleWeb.ConnCase

  @create_attrs %{
    humidity: 120.5,
    pressure: 120.5,
    temperature: 120.5,
    unix_timestamp: 1_684_615_666
  }
  @invalid_attrs %{humidity: nil, pressure: nil, temperature: nil, unix_timestamp: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create weather_snapshot" do
    test "renders weather_snapshot when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/weather_snapshots", weather_snapshot: @create_attrs)
      data = json_response(conn, 201)["data"]

      assert %{
               "id" => id,
               "humidity" => 120.5,
               "pressure" => 120.5,
               "temperature" => 120.5,
               "timestamp" => "2023-05-20T20:47:46"
             } = data

      assert is_integer(id)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/weather_snapshots", weather_snapshot: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "broadcast weather_snapshot" do
    test "returns unpersisted weather_snapshot", %{conn: conn} do
      conn = post(conn, ~p"/api/weather_snapshots/broadcast", weather_snapshot: @create_attrs)
      data = json_response(conn, 200)["data"]

      assert %{
               "id" => nil,
               "humidity" => 120.5,
               "pressure" => 120.5,
               "temperature" => 120.5,
               "timestamp" => "2023-05-20T20:47:46"
             } = data
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/weather_snapshots/broadcast", weather_snapshot: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "error without expected body", %{conn: conn} do
      assert_raise FunctionClauseError, fn ->
        post(conn, ~p"/api/weather_snapshots/broadcast")
      end
    end
  end
end
