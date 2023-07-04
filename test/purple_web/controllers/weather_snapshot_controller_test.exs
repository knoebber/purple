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
    {
      :ok,
      conn:
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("x-purple-api-secret", "test secret")
    }
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

    test "403 with invalid secret", %{conn: conn} do
      conn = put_req_header(conn, "x-purple-api-secret", "invalid")
      conn = post(conn, ~p"/api/weather_snapshots/broadcast", weather_snapshot: @create_attrs)
      assert conn.status == 403
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
