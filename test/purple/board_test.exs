defmodule Purple.BoardTest do
  alias Purple.Board.{ItemEntry, UserBoard}
  alias Purple.Tags.Tag
  import Ecto.Query
  import Purple.Board
  import Purple.BoardFixtures
  use Purple.DataCase

  describe "item, entry, and checkbox crud" do
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

      assert {:ok, item} = create_item(%{description: "test item!"})
      assert item.id > 0
      assert item.last_active_at != nil

      assert {:ok, item_with_children} =
               create_item(%{
                 "description" => "i have #children 👶",
                 "entries" => %{
                   "0" => %{content: "# entry!\n\n- x 1\n- x 2\n\n :)"},
                   "1" => %{content: "- x 1\n- x 2\n\n (dupe #checkboxes are ok between siblings"}
                 }
               })

      assert [entry1, entry2] = list_item_entries(item_with_children.id, :checkboxes)
      assert [%{description: "2"}, %{description: "1"}] = entry1.checkboxes
      assert [%{description: "2"}, %{description: "1"}] = entry2.checkboxes

      assert ["children", "checkboxes"] ==
               Enum.map(Repo.preload(item_with_children, :tags).tags, & &1.name)

      assert {:error, %Ecto.Changeset{valid?: false}} =
               create_item(%{
                 "description" => "hm",
                 "entries" => %{
                   "0" => %{"content" => "- x dupe\n- x dupe"},
                   "1" => %{
                     "content" => "http://localhost:4000/board/26 - #invalid #rollback"
                   }
                 },
                 "priority" => "3",
                 "status" => "TODO"
               })

      # Tags were not created as tx was rolled back
      refute Repo.exists?(where(Tag, [t], t.name == "rollback"))
      refute Repo.exists?(where(Tag, [t], t.name == "invalid"))

      assert {:ok, item} = create_item(%{description: "info", status: :INFO})
      assert is_nil(item.priority)

      assert {:ok, item} = create_item(%{description: "create todo item", status: :TODO})
      assert is_integer(item.priority)
      assert item.priority > 0
    end

    test "update_item/2" do
      item = item_fixture()
      assert {:error, changeset} = update_item(item, %{description: ""})
      assert !changeset.valid?

      assert {:ok, info_item} =
               update_item(
                 item,
                 %{description: "info item", status: :INFO}
               )

      assert info_item.description == "info item"
      assert NaiveDateTime.compare(info_item.updated_at, item.updated_at) == :gt
      assert NaiveDateTime.compare(info_item.last_active_at, item.last_active_at) == :gt
      assert is_nil(info_item.priority)

      assert {:ok, done_item} =
               update_item(
                 info_item,
                 %{description: "done item", status: :DONE}
               )

      assert is_nil(done_item.priority)
      assert done_item.status == :DONE
      assert done_item.description == "done item"

      assert {:ok, todo_item} =
               update_item(
                 done_item,
                 %{description: "todo item", status: :TODO}
               )

      assert is_integer(todo_item.priority)
      assert todo_item.description == "todo item"
    end

    test "set_item_complete!/2" do
      item = item_fixture()
      complete_item = set_item_complete!(item, true)
      assert complete_item.status == :DONE
      assert complete_item.completed_at != nil
      assert is_nil(complete_item.priority)

      incomplete_item = set_item_complete!(complete_item, false)
      assert incomplete_item.status == :TODO
      assert incomplete_item.completed_at == nil
      assert NaiveDateTime.compare(incomplete_item.updated_at, item.updated_at) == :gt
      assert is_integer(incomplete_item.priority)
      assert incomplete_item.priority > 0
    end

    test "pin_item!/2" do
      item = item_fixture()

      pinned_item = pin_item!(item, true)
      assert pinned_item.is_pinned == true

      unpinned_item = pin_item!(pinned_item, false)
      assert unpinned_item.is_pinned == false
      assert NaiveDateTime.compare(unpinned_item.updated_at, item.updated_at) == :gt
    end

    test "toggle_show_item_files!/2" do
      item = item_fixture()

      updated_item = toggle_show_item_files!(item, false)
      assert updated_item.show_files == false

      updated_item = toggle_show_item_files!(item, true)
      assert updated_item.show_files == true
      assert NaiveDateTime.compare(updated_item.updated_at, item.updated_at)
    end

    test "create_item_entry/2" do
      assert {:error, changeset} = create_item_entry(%{}, 0)
      assert !changeset.valid?

      item = item_fixture()

      assert {:ok, entry} =
               create_item_entry(%{content: "# New Entry!!\n\n- x a checkbox!"}, item.id)

      assert %{checkboxes: [%{description: "a checkbox!"}]} = entry

      assert {:error, %Ecto.Changeset{valid?: false}} =
               create_item_entry(%{content: "# duplicate checkbox\n\n- x a\n- x a"}, item.id)
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
                 content: "+ x checkbox1 \n+ x checkbox2\n+ x checkbox 3️⃣! \n\nand a #purpletag"
               })

      assert Enum.any?(get_item!(entry.item_id, :entries, :tags).tags, &(&1.name == "purpletag"))

      assert [entry] = list_item_entries(entry.item_id, :checkboxes)
      assert length(entry.checkboxes) == 3
      assert hd(entry.checkboxes).description != ""

      assert exists1.id == checkbox1.id
      assert exists2.id == checkbox2.id
      assert new_checkbox.description == "checkbox 3️⃣!"
      assert !exists1.is_done and !exists2.is_done and !new_checkbox.is_done

      assert {:error, %Ecto.Changeset{valid?: false}} =
               update_item_entry(entry, %{content: "+ x duplicate\n+ x duplicate"})
    end

    test "delete_entry/2" do
      entry = entry_fixture()
      delete_entry!(entry)
      assert Repo.get(ItemEntry, entry.id) == nil
    end

    test "🚥 side effects" do
      item = item_fixture()

      get_last_active_at = fn ->
        get_item!(item.id).last_active_at
      end

      # This should be the value of item.last_active_at after calling reset_item_timestamps/1
      original_last_active_at = item.last_active_at

      [entry] = item.entries

      # updating an entry with same content doesn't change last_active_at
      update_item_entry(entry, %{content: entry.content})
      assert original_last_active_at == get_last_active_at.()

      # updating an entry with new content changes last_active_at
      reset_item_timestamps(item)
      update_item_entry(entry, %{content: "new content, no checkbox or tag"})
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt

      # deleting an entry that has no checkboxes or entries doesn't update last_active_at
      reset_item_timestamps(item)
      delete_entry!(entry)
      assert original_last_active_at == get_last_active_at.()

      # Last active is updated after creating new entry
      {:ok, new_entry_1} = create_item_entry(%{content: "new entry 1"}, item.id)
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt

      # Last active is updated after updating an entry, and new tags are set.
      reset_item_timestamps(item)
      {:ok, entry_with_tag} = update_item_entry(new_entry_1, %{content: "#purpletag"})
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt

      assert Enum.any?(get_item!(entry.item_id, :entries, :tags).tags, &(&1.name == "purpletag"))

      # Last active is updated after updating an entry, and new checkbox is set.
      {:ok, new_entry_2} = create_item_entry(%{content: "new entry 2"}, item.id)
      reset_item_timestamps(item)
      {:ok, entry_with_checkbox} = update_item_entry(new_entry_2, %{content: "+ x acheckbox"})
      assert ["acheckbox"] == Enum.map(entry_with_checkbox.checkboxes, & &1.description)
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt

      # Last active is updated after deleting an entry that has tags, and tag is deleted
      reset_item_timestamps(item)
      delete_entry!(entry_with_tag)
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt
      refute Enum.any?(get_item!(entry.item_id, :entries, :tags).tags, &(&1.name == "purpletag"))

      # Last active is updated after deleting an entry that has checkbox.
      reset_item_timestamps(item)
      delete_entry!(entry_with_checkbox)
      assert NaiveDateTime.compare(original_last_active_at, get_last_active_at.()) == :lt
    end
  end

  describe "user board crud" do
    test "fixture works" do
      ub = user_board_fixture()
      assert length(ub.tags) > 0
    end

    test "create_user_board/2" do
      item = item_fixture()
      [tag | _] = item.tags

      assert_raise Ecto.ConstraintError, ~r/user_id_fkey/, fn ->
        create_user_board(%{"name" => "invalid", "tags" => [tag]}, 0)
      end

      user = Purple.AccountsFixtures.user_fixture()

      {:error, changeset} =
        create_user_board(
          %{"name" => "invalid", "tags" => [%{id: 1, name: "i dont exist"}]},
          user.id
        )

      refute changeset.valid?

      {:ok, %UserBoard{tags: []}} =
        create_user_board(
          %{"name" => "invalid", "tags" => []},
          user.id
        )

      {:ok, ub} =
        create_user_board(
          %{"name" => "valid", "tags" => [tag]},
          user.id
        )

      assert ub.tags == [tag]
    end

    test "update_user_board/2" do
      ub = user_board_fixture()

      {:error, changeset} =
        update_user_board(ub, %{"name" => "invalid", "tags" => [%{id: 1, name: "i dont exist"}]})

      refute changeset.valid?

      {:error, changeset} =
        update_user_board(ub, %{"name" => "invalid", "tags" => [%{id: 1, name: "i dont exist"}]})

      refute changeset.valid?

      {:ok, %UserBoard{} = ub} = update_user_board(ub, %{"name" => "ok", "tags" => []})
      assert ub.name == "ok"

      {:ok, %UserBoard{} = ub} = update_user_board(ub, %{"name" => "new name", "tags" => ub.tags})
      assert ub.name == "new name"

      item_fixture(%{description: "#newtagforuserboard"})
      new_tag = Repo.one!(where(Purple.Tags.Tag, [t], t.name == ^"newtagforuserboard"))

      {:ok, %UserBoard{} = ub} = update_user_board(ub, %{"tags" => [new_tag]})
      assert ub.tags == [new_tag]
    end

    test "delete_user_board!/1" do
      item_fixture(%{description: "#tagfordelete"})
      ub = user_board_fixture()
      new_tag = Repo.one!(where(Purple.Tags.Tag, [t], t.name == ^"tagfordelete"))

      {:ok, %UserBoard{} = ub} =
        update_user_board(ub, %{"name" => "whatever.", "tags" => [new_tag]})

      assert ub.tags == [new_tag]
      assert ub.name == "whatever."
      delete_user_board!(ub.id)
      # The UB is deleted
      refute Repo.exists?(where(UserBoard, [b], b.id == ^ub.id))

      # The join ref is deleted
      refute Repo.exists?(where(Purple.Tags.UserBoardTag, [ubt], ubt.tag_id == ^new_tag.id))

      # The tag ref still exists
      assert Repo.exists?(where(Purple.Tags.Tag, [t], t.id == ^new_tag.id))
    end
  end

  describe "user boards" do
    test "get_user_board_item_status_map" do
      item_fixture(%{description: "info1 #ubtest", status: :INFO})
      item_fixture(%{description: "info2 #ubtest", status: :INFO})
      item_fixture(%{description: "done1 #ubtest", status: :DONE})
      tags = item_fixture(%{description: "todo1 #ubtest", status: :TODO})

      ub =
        user_board_fixture(%{
          "name" => "test status map",
          "tags" => [Purple.Tags.get_tag!("ubtest")]
        })

      assert %{
               todo: [%{description: "todo1 #ubtest"}],
               done: [%{description: "done1 #ubtest"}],
               info: [%{description: "info2 #ubtest"}, %{description: "info1 #ubtest"}]
             } = get_user_board_item_status_map(ub)
    end
  end
end
