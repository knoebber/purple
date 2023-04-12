defmodule Purple.HistoryTest do
  alias Purple.History
  alias Purple.History.ViewedUrl
  import Purple.AccountsFixtures
  use Purple.DataCase

  describe "viewed urls" do
    test "save_url/2" do
      %{id: user_id} = user_fixture()
      [example] = History.save_url(user_id, "example.com")

      assert [%ViewedUrl{url: "example.com", user_id: user_id}] = [example]

      result = History.save_url(user_id, "example.com")
      example = Map.put(example, :freshness, 1)
      assert [example] == result

      for i <- 1..History.max_num_user_urls() do
        History.save_url(user_id, "example.com/i/#{i}")
      end

      all_urls = History.list_user_viewed_urls(user_id)
      assert length(all_urls) == History.max_num_user_urls()

      # oldest history item is deleted after inserting the max amount of URLs
      [first | _] = all_urls
      refute first == example

      assert List.last(all_urls).url == "example.com/i/1"
      # Saving duplicate doesn't change sort order, but it does protect from being popped
      History.save_url(user_id, "example.com/i/1")
      assert List.last(History.list_user_viewed_urls(user_id)).url == "example.com/i/1"
      updated_list = History.save_url(user_id, "example.com/whatever")
      assert History.list_user_viewed_urls(user_id) == updated_list
      assert List.last(updated_list).url == "example.com/i/1"
      # i/2 was popped
      assert Enum.find(updated_list, &(&1.url == "example.com/i/2")) == nil
    end
  end
end
