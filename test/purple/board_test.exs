defmodule Purple.BoardTest do
  use Purple.DataCase
  alias Purple.Repo

  import Purple.Board
  import Purple.BoardFixtures

  describe "items" do
    test "item, entry, and tags are created" do
      item = item_fixture()

      assert length(item.entries) > 0
      assert length(item.tags) > 0
      assert item.description != ""
      assert item.entries |> Enum.at(0) |> Map.get(:content) |> String.length() > 0
      assert item.tags |> Enum.at(0) |> Map.get(:name) |> String.length() > 0

      item_with_children = get_item!(item.id, :entries, :tags)
      assert length(item_with_children.entries) > 0
      assert length(item_with_children.tags) > 0
    end
  end

  describe "save_item/4" do
    test ":create_item" do
    end

    test ":update_item" do
    end

    test ":update_entry" do
    end

    test ":create_entry" do
    end

    test ":delete_entry" do
    end
  end

  describe "item entries" do
    test "sync_entry_checkboxes/1" do
      entry = entry_fixture(%{content: "+ x checkbox1 \n+ x checkbox2"})

      {
        :ok,
        %{checkboxes: [checkbox2, checkbox1]}
      } = sync_entry_checkboxes(Repo.preload(entry, :checkboxes))

      assert checkbox1.description == "checkbox1"
      assert checkbox2.description == "checkbox2"

      {:ok, entry} =
        update_item_entry(entry, %{content: "+ x checkbox1 \n+ x checkbox2\n+ x checkbox 3️⃣! "})

      {
        :ok,
        %{checkboxes: checkboxes}
      } = sync_entry_checkboxes(Repo.preload(entry, :checkboxes))

      assert length(checkboxes) == 3
      [new_checkbox, exists2, exists1] = checkboxes
      assert exists1.id == checkbox1.id
      assert exists2.id == checkbox2.id
      assert new_checkbox.description == "checkbox 3️⃣!"
    end
  end
end
