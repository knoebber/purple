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

  describe "user board" do
    test "show board", %{conn: conn} do
      user_board = user_board_fixture(%{"user" => user_fixture()})

      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board/#{user_board.id}")

      items = Purple.Board.list_items(%{tag: Enum.map(user_board.tags(& &1.name))})

      List.each(items, fn item ->
        assert html =~ item.description
      end)
    end

    test "show board settings", %{conn: conn} do
      user_board_fixture(%{"name" => "An Example Board Name!"})

      assert {:ok, _, html} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/board/settings")

      html =~ "An Example Board Name!"
    end

    test "edit board settings", %{conn: conn} do
      user = user_fixture()
      user_board = user_board_fixture(%{"name" => "Editable board", "user" => user})

      assert {:ok, _, html} =
               conn
               |> log_in_user(user)
               |> live(~p"/board/settings/#{user_board}")

      html =~ "Editable Board"
    end
  end
end
