defmodule PurpleWeb.FancyLinkTest do
  import Purple.ActivitiesFixtures
  import Purple.BoardFixtures
  import PurpleWeb.FancyLink
  use Purple.DataCase

  doctest PurpleWeb.FancyLink

  describe "fancy link" do
    test "extract_routes_from_markdown\1" do
      assert extract_routes_from_markdown("") == []
      assert extract_routes_from_markdown("# wee") == []
      assert extract_routes_from_markdown("#wee") == []

      assert extract_routes_from_markdown("https://example.com/ok\nexample.com/ok") ==
               []

      assert extract_routes_from_markdown("https://example.com/ok\nexample.com/ok") ==
               []

      assert extract_routes_from_markdown("localhost:4000/") == []
      assert extract_routes_from_markdown("localhost:4000/ok/ok") == []
      assert extract_routes_from_markdown("http://localhost:4000/ok/ok") == []

      assert extract_routes_from_markdown("http://localhost:4000/board") == [
               {
                 "http://localhost:4000/board",
                 PurpleWeb.BoardLive.Index,
                 %{}
               }
             ]

      assert extract_routes_from_markdown(" http://localhost:4000/finance ") == [
               {
                 "http://localhost:4000/finance",
                 PurpleWeb.FinanceLive.Index,
                 %{}
               }
             ]

      assert(
        extract_routes_from_markdown(
          "# Fancy Links\n\n* http://localhost:4000/board/item/105\n* http://localhost:4000/finance/transactions/538"
        ) == [
          {
            "http://localhost:4000/board/item/105",
            PurpleWeb.BoardLive.ShowItem,
            %{"id" => "105"}
          },
          {
            "http://localhost:4000/finance/transactions/538",
            PurpleWeb.FinanceLive.ShowTransaction,
            %{"id" => "538"}
          }
        ]
      )

      assert extract_routes_from_markdown(~s"""
             # Test header
             http://localhost:4000/runs/1? (fancy 1)

             stuff, whatever
             [not fancy](http://localhost:4000/board/1
             http://localhost:4000/board/3 (fancy 2)

             * https://example.com/not/fancy
             * http://localhost:4000/board/item/10?a=1&b=3 (fancy 3)
             * https://example.com/not/fancy
             """) == [
               {
                 "http://localhost:4000/runs/1?",
                 PurpleWeb.RunLive.Show,
                 %{"id" => "1"}
               },
               {
                 "http://localhost:4000/board/3",
                 PurpleWeb.BoardLive.Board,
                 %{"user_board_id" => "3"}
               },
               {
                 "http://localhost:4000/board/item/10?a=1&b=3",
                 PurpleWeb.BoardLive.ShowItem,
                 %{"id" => "10", "a" => "1", "b" => "3"}
               }
             ]
    end

    test "get_fancy_link_title/1" do
      item = item_fixture()
      {_, module, params} = build_route_tuple("http://localhost:4000/board/item/#{item.id}")
      title = get_fancy_link_title(module, params)
      assert title =~ item.description

      title = get_fancy_link_title(PurpleWeb, %{})
      assert title == nil
    end

    test "build_fancy_link_groups/1" do
      item = item_fixture()
      item_2 = item_fixture(%{description: "fancy links", status: :DONE})
      run = run_fixture()

      route_tuples =
        extract_routes_from_markdown(~s"""
        http://localhost:4000/board/item/#{item.id}
        http://localhost:4000/board/item/#{item_2.id}
        nil
        http://localhost:4000/board/item/nil
        http://localhost:4000/board
        example.com
        http://localhost:4000/runs/#{run.id}
        """)

      fancy_link_groups = build_fancy_link_groups(route_tuples)

      assert fancy_link_groups == %{
               "🌻" => [
                 {"http://localhost:4000/board/item/#{item_2.id}", "fancy links (DONE)"},
                 {"http://localhost:4000/board/item/#{item.id}", "Test Item 🌞 (TODO)"}
               ],
               "🏃" => [{"http://localhost:4000/runs/#{run.id}", "120.5 miles@N/A in N/A"}]
             }
    end

    test "build_fancy_link_map/1" do
      assert build_fancy_link_map([]) == %{}
      assert build_fancy_link_map([{"", PurpleWeb, %{}}]) == %{}

      item = item_fixture()
      item_2 = item_fixture(%{description: "fancy links", status: :DONE})

      route_tuples =
        extract_routes_from_markdown(~s"""
        http://localhost:4000/board/item/#{item.id}
        http://localhost:4000/board/item/#{item_2.id}
        nil
        example.com
        """)

      fancy_link_map = build_fancy_link_map(route_tuples)

      assert fancy_link_map == %{
               "http://localhost:4000/board/item/#{item.id}" => "🌻 · Test Item 🌞 (TODO)",
               "http://localhost:4000/board/item/#{item_2.id}" => "🌻 · fancy links (DONE)"
             }
    end
  end
end
