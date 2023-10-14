defmodule PurpleWeb.BoardLiveTest do
  use PurpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import Purple.AccountsFixtures
  import Purple.FinanceFixtures

  describe "index page" do
    test "redirect when not logged in", %{conn: conn} do
      assert {:error,
              {:redirect,
               %{flash: %{"error" => "You must log in to access this page."}, to: "/users/log_in"}}} =
               live(conn, ~p"/finance")
    end

    test "ok", %{conn: conn} do
      assert {:ok, _, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/finance")
    end

    test "displays logged in users transactions", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      tx1 = transaction_fixture(%{dollars: "1000.12"}, user: user1)
      tx2 = transaction_fixture(%{dollars: "123.12"}, user: user2)

      assert {:ok, view, _} =
               conn
               |> log_in_user(user1)
               |> live(~p"/finance")

      tbody =
        view
        |> element("tbody")
        |> render()

      refute tbody =~ "123.123"
      assert tbody =~ "1000.12"

      assert {:ok, view, _} =
               conn
               |> log_in_user(user2)
               |> live(~p"/finance")

      tbody =
        view
        |> element("tbody")
        |> render()

      refute tbody =~ "1000.12"
      assert tbody =~ "123.12"
    end
  end

  describe "show merchant" do
    test "ok", %{conn: conn} do
      m = merchant_fixture()

      assert {:ok, view, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/finance/merchants/#{m}")

      html = render(view)
      assert html =~ m.name
      assert html =~ m.description
    end

    test "shows user transactions", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      m = merchant_fixture()
      tx1 = transaction_fixture(%{dollars: "1000.12"}, user: user1, merchant: m)
      tx2 = transaction_fixture(%{dollars: "111.00"}, user: user2, merchant: m)
      tx3 = transaction_fixture(%{dollars: "222.00"}, user: user2, merchant: m)
      tx4 = transaction_fixture(%{dollars: "333.00"}, user: user2, merchant: m)

      assert {:ok, view, _} =
               conn
               |> log_in_user(user1)
               |> live(~p"/finance/merchants/#{m}")

      html = render(view)

      assert html =~ "1 transaction"
      assert html =~ tx1.dollars
      refute html =~ tx2.dollars

      assert {:ok, view, _} =
               conn
               |> log_in_user(user2)
               |> live(~p"/finance/merchants/#{m}")

      html = render(view)

      assert html =~ "3 transactions"
      assert html =~ tx2.dollars
      assert html =~ tx3.dollars
      assert html =~ tx4.dollars
      refute html =~ tx1.dollars
    end
  end
end
