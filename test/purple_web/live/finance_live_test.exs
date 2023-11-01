defmodule PurpleWeb.FinanceLiveTest do
  alias Purple.Finance
  import Phoenix.LiveViewTest
  import Purple.AccountsFixtures
  import Purple.FinanceFixtures
  use PurpleWeb.ConnCase

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

  describe "create transaction page" do
    test "ok", %{conn: conn} do
      pm = payment_method_fixture("CC 420 💳")
      u = user_fixture()

      assert {:ok, view, _} =
               conn
               |> log_in_user(u)
               |> live(~p"/finance/transactions/create")

      form = view |> element("form") |> render()
      # payment method name is present in form.
      assert form =~ pm.name
    end
  end

  describe "merchant index" do
    test "ok", %{conn: conn} do
      u = user_fixture()
      m = merchant_name_fixture("testing merchant index")
      t = transaction_fixture(%{}, user: u, merchant_name: m)

      assert {:ok, view, _} =
               conn
               |> log_in_user(u)
               |> live(~p"/finance/merchants")

      content = render(view)
      assert content =~ "testing merchant index"
    end
  end

  describe "show merchant" do
    test "ok", %{conn: conn} do
      mn = merchant_name_fixture()

      assert {:ok, view, _} =
               conn
               |> log_in_user(user_fixture())
               |> live(~p"/finance/merchants/#{mn.merchant_id}")

      html = render(view)
      assert html =~ mn.name
      assert html =~ mn.merchant.description
    end

    test "shows user transactions", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      m = merchant_name_fixture()
      tx1 = transaction_fixture(%{dollars: "1000.12"}, user: user1, merchant_name: m)
      tx2 = transaction_fixture(%{dollars: "111.00"}, user: user2, merchant_name: m)
      tx3 = transaction_fixture(%{dollars: "222.00"}, user: user2, merchant_name: m)
      tx4 = transaction_fixture(%{dollars: "333.00"}, user: user2, merchant_name: m)

      assert {:ok, view, _} =
               conn
               |> log_in_user(user1)
               |> live(~p"/finance/merchants/#{m.merchant}")

      html = render(view)

      assert html =~ "1 transaction"
      assert html =~ tx1.dollars
      refute html =~ tx2.dollars

      assert {:ok, view, _} =
               conn
               |> log_in_user(user2)
               |> live(~p"/finance/merchants/#{m.merchant}")

      html = render(view)

      assert html =~ "3 transactions"
      assert html =~ tx2.dollars
      assert html =~ tx3.dollars
      assert html =~ tx4.dollars
      refute html =~ tx1.dollars
    end

    test "shared budget math works", %{conn: conn} do
      sb = Finance.create_shared_budget!("Shared Budget Test")

      assert_user_total = fn user_who_is_behind, total ->
        assert {:ok, view, _} =
                 conn
                 |> log_in_user(user_who_is_behind)
                 |> live(~p"/finance/shared_budgets/#{sb}")

        h2_html =
          view
          |> element("h2:fl-contains('#{user_who_is_behind.email}')")
          |> render

        assert h2_html =~ user_who_is_behind.email
        assert h2_html =~ total
      end

      create_shared_tx = fn user, dollars, type ->
        {:ok, stx} =
          Finance.create_shared_transaction(sb.id, %{
            transaction_id: transaction_fixture(%{dollars: dollars}, user: user).id,
            type: type
          })

        stx
      end

      create_adjustment = fn user, dollars, type ->
        {:ok, adj} =
          Finance.create_shared_budget_adjustment(sb.id, %{
            user_id: user.id,
            dollars: dollars,
            type: type
          })

        adj
      end

      # E.G. Bob and Sue live together and Bob spends $1000.00 on groceries. Then, Sue could get even with Bob by paying him $500.00
      bob = user_fixture()
      sue = user_fixture()

      create_shared_tx.(bob, "1000.00", :SHARE)

      # Instead of paying Bob $500 in cash, Sue buys Bob a new phone for $510. This isn't shared, so it's entered as a CREDIT.
      create_shared_tx.(sue, "510.00", :CREDIT)

      # Shared budget should show that Bob is down 10 dollars.
      assert_user_total.(bob, "10.00")

      create_adjustment.(sue, "15.00", :SHARE)
      assert_user_total.(bob, "17.50")

      create_adjustment.(bob, "1.12", :CREDIT)

      assert_user_total.(bob, "16.38")
    end
  end
end
