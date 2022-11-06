defmodule PurpleWeb.FancyLinkTest do
  use Purple.DataCase
  import PurpleWeb.FancyLink

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
             http://localhost:4000/runs/1 (fancy 1)

             stuff, whatever
             [not fancy](http://localhost:4000/board/1
             http://localhost:4000/board/3 (fancy 2)

             * https://example.com/not/fancy
             * http://localhost:4000/board/item/10 (fancy 3)
             * https://example.com/not/fancy
             """) == [
               {
                 "http://localhost:4000/runs/1",
                 PurpleWeb.RunLive.Show,
                 %{"id" => "1"}
               },
               {
                 "http://localhost:4000/board/3",
                 PurpleWeb.BoardLive.Index,
                 %{"user_board_id" => "3"}
               },
               {
                 "http://localhost:4000/board/item/10",
                 PurpleWeb.BoardLive.ShowItem,
                 %{"id" => "10"}
               }
             ]
    end
  end
end
