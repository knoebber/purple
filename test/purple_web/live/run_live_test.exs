defmodule PurpleWeb.RunLiveTest do
  use PurpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import Purple.AccountsFixtures

  describe "index page" do
    test "redirect when not logged in", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{flash: %{"error" => "You must log in to access this page."}, to: "/users/log_in"}}} =
               live(conn, ~p"/board")
    end

    test "ok when logged in", %{conn: conn} do
      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/runs")

      assert html =~ "miles"
    end
  end

  describe "create" do
    test "ok", %{conn: conn} do
      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/runs/create")

      assert html =~ "miles"
    end
  end
end
