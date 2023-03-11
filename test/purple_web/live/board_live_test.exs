defmodule PurpleWeb.BoardLiveTest do
  use PurpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import Purple.AccountsFixtures
  import Purple.BoardFixtures

  describe "index page" do
    test "redirect when not logged in", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{flash: %{"error" => "You must log in to access this page."}, to: "/users/log_in"}}} =
               live(conn, ~p"/board")
    end

    test "searching works", %{conn: conn} do
      item_fixture(%{description: "grape"})
      item_fixture(%{description: "apple #liveview"})
      item_fixture(%{description: "banana, #boardlivetest"})

      assert {:ok, view, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board")

      tbody =
        view
        |> element("tbody")
        |> render()

      assert tbody =~ "grape"
      assert tbody =~ "apple"
      assert tbody =~ "banana"

      assert {:ok, view, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board?query=grape")

      tbody =
        view
        |> element("tbody")
        |> render()

      refute tbody =~ "banana"
      assert tbody =~ "grape"

      assert {:ok, view, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board?tag=boardlivetest")

      tbody =
        view
        |> element("tbody")
        |> render()

      assert tbody =~ "banana"
      refute tbody =~ "apple"
      refute tbody =~ "grape"

      result =
        view
        |> element("form")
        |> render_change(%{
          "_target" => ["filter", "tag"],
          "filter" => %{"query" => "", "tag" => "liveview"}
        })

      assert result =~ "apple"
      refute result =~ "grape"
    end
  end

  describe "create page" do
    test "ok", %{conn: conn} do
      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board/item/create")

      html =~ "entry"
    end
  end

  describe "show item" do
    test "edit entry", %{conn: conn} do
      item = item_fixture()
      [entry] = item.entries

      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board/item/#{item.id}/entry/#{entry.id}")

      html =~ "Save"
    end
  end
end
