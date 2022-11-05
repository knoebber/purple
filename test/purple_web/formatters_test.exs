defmodule PurpleWeb.FormattersTest do
  use Purple.DataCase
  import PurpleWeb.Formatters

  describe "formatters" do
    test "extract_routes_from_markdown\1" do
      # TODO: assert url and delete me
      IO.inspect(Application.get_env(:purple, PurpleWeb.Endpoint)[:url][:host])
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
                 PurpleWeb.BoardLive.Index,
                 %{}
               }
             ]

      assert extract_routes_from_markdown(" http://localhost:4000/finance ") == [
               {
                 PurpleWeb.FinanceLive.Index,
                 %{}
               }
             ]

      assert extract_routes_from_markdown(~s"""
             # Test header
             http://localhost:4000/runs/1 (fancy 1)

             stuff, whatever
             [not fancy](http://localhost:4000/board/1
             http://localhost:4000/board/3 (fancy 2)
             http://localhost:4000/board/item/10 (fancy 3)
             https://example.com/not/fancy
             """) == [
               {PurpleWeb.RunLive.Show, %{"id" => "1"}},
               {PurpleWeb.BoardLive.Index, %{"user_board_id" => "3"}},
               {PurpleWeb.BoardLive.ShowItem, %{"id" => "10"}}
             ]
    end
  end
end
