defmodule PurpleWeb.SideNavTest do
  @side_nav_selector "#js-side-nav"

  use PurpleWeb.ConnCase

  import Phoenix.LiveViewTest
  import Purple.AccountsFixtures
  import Purple.BoardFixtures
  import Purple.ActivitiesFixtures

  describe "side nav" do
    test "renders descriptions of recently viewed links", %{conn: conn} do
      user = user_fixture()

      navigate = fn to ->
        assert {:ok, view, _} =
                 conn
                 |> log_in_user(user)
                 |> live(to)

        # Mocks the "global_navigate" event sent from JS
        view
        |> element(@side_nav_selector)
        |> render_hook(:global_navigate, %{to: PurpleWeb.WebHelpers.make_full_url(to)})
      end

      item1 = item_fixture(%{description: "foo baz"})
      item2 = item_fixture(%{description: "another item"})
      run1 = run_fixture(%{miles: 777.77})
      run2 = run_fixture(%{miles: 420.0})

      navigate.(~p"/board/item/#{item1}")
      navigate.(~p"/runs/#{run1}")
      navigate.(~p"/runs/#{run2}")
      navigate.(~p"/board/item/#{item2}")

      assert {:ok, view, _} =
               conn
               |> log_in_user(user)
               |> live(~p"/board/item/#{item1}")

      side_nav_html =
        view
        |> element(@side_nav_selector)
        |> render()

      assert side_nav_html =~ "foo baz"
      assert side_nav_html =~ "another item"
      assert side_nav_html =~ "777.77"
      assert side_nav_html =~ "420.0"
    end
  end
end
