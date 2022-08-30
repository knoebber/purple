defmodule Purple.BoardTest do
  use Purple.DataCase
  alias Purple.Board.CheckBox
  alias Purple.Board.Item
  alias Purple.Board.ItemEntry
  alias Purple.Repo

  import Purple.Board
  import Purple.BoardFixtures

  describe "item and entry crud" do
    test "fixture is expected" do
      item = item_fixture()

      assert length(item.entries) > 0
      assert length(item.tags) > 0
      assert item.description != ""
      assert item.entries |> Enum.at(0) |> Map.get(:content) |> String.length() > 0
      assert item.tags |> Enum.at(0) |> Map.get(:name) |> String.length() > 0

      item = get_item!(item.id, :entries, :tags)
      assert length(item.entries) > 0
      assert length(item.tags) > 0

      [entry] = item.entries
      entry = Repo.preload(entry, :checkboxes)
      assert length(entry.checkboxes) > 0
    end

    test "create_item/1" do
      {:error, changeset} = Purple.Board.create_item(%{})
    end

    test "update_item/2" do
      item = item_fixture()
      {:error, changeset} = Purple.Board.update_item(item, %{description: ""})
    end

    test "create_item_entry/2" do
      {:error, changeset} = Purple.Board.create_item_entry(%{}, 0)
    end

    test "update_item_entry/2" do
      entry = entry_fixture()
      {:error, changeset} = Purple.Board.update_item_entry(entry, %{content: ""})
    end

    test "delete_entry/2" do
      entry = entry_fixture()
      dbg entry
      Purple.Board.delete_entry!(entry)
      assert Repo.get(ItemEntry, entry.id) == nil
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
