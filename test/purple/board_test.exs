defmodule Purple.BoardTest do
  use Purple.DataCase
  alias Purple.Board.ItemEntry

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
      assert {:error, changeset} = create_item(%{})
      assert !changeset.valid?
    end

    test "update_item/2" do
      item = item_fixture()
      assert {:error, changeset} = update_item(item, %{description: ""})
      assert !changeset.valid?
    end

    test "create_item_entry/2" do
      assert {:error, changeset} = create_item_entry(%{}, 0)
      assert !changeset.valid?

      item = item_fixture()

      assert {:ok, entry} =
               create_item_entry(%{content: "# New Entry!!\n\n- x a checkbox!"}, item.id)

      assert %{checkboxes: [%{description: "a checkbox!"}]} = entry

      assert {:error, changeset} =
               create_item_entry(%{content: "# duplicate checkbox\n\n- x a\n- x a"}, item.id)

      assert !changeset.valid?
    end

    test "update_item_entry/2" do
      entry = entry_fixture()
      assert {:error, changeset} = update_item_entry(entry, %{content: ""})
      assert !changeset.valid?

      assert {:ok, %{checkboxes: [checkbox2, checkbox1]}} =
               update_item_entry(entry, %{content: "+ x checkbox1 \n+ x checkbox2"})

      assert checkbox1.description == "checkbox1"
      assert checkbox2.description == "checkbox2"

      assert {:ok, %{checkboxes: [new_checkbox, exists2, exists1]}} =
               update_item_entry(entry, %{
                 content: "+ x checkbox1 \n+ x checkbox2\n+ x checkbox 3️⃣! "
               })

      assert [entry] = list_item_entries(entry.item_id, :checkboxes)
      assert length(entry.checkboxes) == 3
      assert hd(entry.checkboxes).description != ""

      assert exists1.id == checkbox1.id
      assert exists2.id == checkbox2.id
      assert new_checkbox.description == "checkbox 3️⃣!"
      assert !exists1.is_done and !exists2.is_done and !new_checkbox.is_done

      assert {:error, changeset} =
               update_item_entry(entry, %{content: "+ x duplicate\n+ x duplicate"})

      assert !changeset.valid?
    end

    test "delete_entry/2" do
      entry = entry_fixture()
      delete_entry!(entry)
      assert Repo.get(ItemEntry, entry.id) == nil
    end
  end
end
