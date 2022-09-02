defmodule Purple.Board do
  @moduledoc """
  Context for managing boards, items, and entries.
  """

  alias Purple.Board.{ItemEntry, Item, UserBoard, EntryCheckbox}
  alias Purple.Repo
  alias Purple.Tags
  alias Purple.Tags.{UserBoardTag}

  import Ecto.Query

  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  def change_item_entry(%ItemEntry{} = entry, attrs \\ %{}) do
    ItemEntry.changeset(entry, attrs)
  end

  defp item_transaction(f) do
    Repo.transaction(fn ->
      result = f.()

      case result do
        {:error, changeset} ->
          Repo.rollback(changeset)

        _ ->
          result
      end
    end)
  end

  def create_item(params) do
    changeset = Item.changeset(%Item{}, params)

    item_transaction(fn ->
      with {:ok, item} <- Repo.insert(changeset),
           {:ok, _} <- post_process_item(item.id) do
        item
      end
    end)
  end

  def update_item(%Item{} = item, params) do
    changeset = Item.changeset(item, params)

    item_transaction(fn ->
      with {:ok, item} <- Repo.update(changeset),
           {:ok, _} <- post_process_item(item.id) do
        item
      end
    end)
  end

  def create_item_entry(params, item_id) when is_map(params) and is_integer(item_id) do
    changeset = ItemEntry.changeset(%ItemEntry{item_id: item_id}, params)

    item_transaction(fn ->
      with {:ok, entry} <- Repo.insert(changeset),
           {:ok, entry} <- post_process_item(item_id, Map.put(entry, :checkboxes, [])) do
        entry
      end
    end)
  end

  def update_item_entry(%ItemEntry{} = entry, params) do
    changeset = ItemEntry.changeset(entry, params)

    item_transaction(fn ->
      with {:ok, entry} <- Repo.update(changeset),
           {:ok, entry} <- post_process_item(entry.item_id, Repo.preload(entry, :checkboxes)) do
        entry
      end
    end)
  end

  def delete_entry!(%ItemEntry{} = item_entry) do
    item_transaction(fn ->
      Repo.delete!(item_entry)
      {:ok, _} = post_process_item(item_entry.item_id)
      :ok
    end)
  end

  def get_entry_checkboxes(%ItemEntry{id: id} = entry) when is_integer(id) do
    checkbox_descriptions = Purple.Markdown.extract_checkbox_content(entry.content)

    persisted_checkboxes =
      EntryCheckbox
      |> where([x], x.description in ^checkbox_descriptions)
      |> where([x], x.item_entry_id == ^entry.id)
      |> Repo.all()

    Enum.map(
      checkbox_descriptions,
      fn description ->
        persisted = Enum.find(persisted_checkboxes, &(&1.description == description))

        if persisted do
          EntryCheckbox.changeset(persisted)
        else
          EntryCheckbox.changeset(EntryCheckbox.new(entry.id, description))
        end
      end
    )
  end

  def sync_entry_checkboxes(%ItemEntry{checkboxes: checkboxes} = entry)
      when is_list(checkboxes) do
    entry
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:checkboxes, get_entry_checkboxes(entry))
    |> Repo.update()
  end

  def post_process_item(item_id, entry \\ nil) when is_integer(item_id) do
    {:ok, _} = Purple.Tags.sync_tags(item_id, :item)

    if entry do
      sync_entry_checkboxes(entry)
    else
      {:ok, item_id}
    end
  end

  def get_item!(id) do
    Repo.get!(Item, id)
  end

  def get_item!(id, :entries, :tags) do
    Repo.one!(
      from i in Item,
        left_join: e in assoc(i, :entries),
        left_join: t in assoc(i, :tags),
        where: i.id == ^id,
        preload: [entries: e, tags: t]
    )
  end

  defp list_item_entries_query(item_id) do
    ItemEntry
    |> where([ie], ie.item_id == ^item_id)
    |> order_by(asc: :sort_order, desc: :inserted_at)
  end

  def list_item_entries(item_id) do
    item_id
    |> list_item_entries_query()
    |> Repo.all()
  end

  def list_item_entries(item_id, :checkboxes) do
    item_id
    |> list_item_entries_query()
    |> join(:left, [entry], x in assoc(entry, :checkboxes))
    |> preload([_, x], [checkboxes: x])
    |> Repo.all()
  end

  def set_item_complete!(%Item{} = item, true) do
    item
    |> Item.changeset(%{
      completed_at: NaiveDateTime.utc_now(),
      status: :DONE
    })
    |> Repo.update!()
  end

  def set_item_complete!(%Item{} = item, false) do
    item
    |> Item.changeset(%{
      completed_at: nil,
      status: :TODO
    })
    |> Repo.update!()
  end

  def pin_item(%Item{} = item, is_pinned) do
    item
    |> Item.changeset(%{is_pinned: is_pinned})
    |> Repo.update()
  end

  def collapse_item_entries(entry_ids, is_collapsed) do
    ItemEntry
    |> where([ie], ie.id in ^entry_ids)
    |> Repo.update_all(set: [is_collapsed: is_collapsed])
  end

  def toggle_show_item_files(item_id, show_files) do
    Item
    |> where([i], i.id == ^item_id)
    |> Repo.update_all(set: [show_files: show_files])
  end

  def save_item_entry_sort_order(entries) do
    Repo.transaction(fn ->
      Enum.each(entries, fn entry ->
        ItemEntry
        |> where([ie], ie.id == ^entry.id)
        |> Repo.update_all(set: [sort_order: entry.sort_order])
      end)
    end)
  end

  defp item_text_search(query, %{query: q}) do
    where(query, [i], ilike(i.description, ^"%#{q}%"))
  end

  defp item_text_search(query, _), do: query

  defp item_done_filter(query, %{show_done: true}) do
    query
  end

  defp item_done_filter(query, _) do
    where(query, [i], i.status != ^"DONE")
  end

  def list_items(filter \\ %{}) do
    filter =
      if Map.has_key?(filter, :query) do
        %{query: filter.query, show_done: true}
      else
        filter
      end

    Item
    |> order_by(desc: :is_pinned, desc: :completed_at, asc: :priority)
    |> item_text_search(filter)
    |> item_done_filter(filter)
    |> Tags.filter_by_tag(filter, :item)
    |> Repo.all()
  end

  def list_user_board_items(user_board = %UserBoard{tags: tags} = user_board)
      when is_list(tags) do
    list_items(%{tag: tags, show_done: user_board.show_done})
  end

  def list_user_boards(user_id) do
    Repo.all(
      from ub in UserBoard,
        left_join: t in assoc(ub, :tags),
        where: ub.user_id == ^user_id,
        order_by: [ub.name],
        preload: [tags: t]
    )
  end

  def list_entry_checkboxes(entry_id) do
    Repo.all(where(EntryCheckbox, [ec], ec.item_entry_id == ^entry_id))
  end

  def get_user_board!(id) do
    Repo.one(
      from ub in UserBoard,
        left_join: t in assoc(ub, :tags),
        where: ub.id == ^id,
        preload: [tags: t]
    )
  end

  def get_default_user_board(user_id) do
    case Repo.one(
           from ub in UserBoard,
             left_join: t in assoc(ub, :tags),
             where: ub.user_id == ^user_id,
             where: ub.is_default == true,
             preload: [tags: t]
         ) do
      nil -> %UserBoard{}
      board -> board
    end
  end

  def add_user_board_tag(user_board_id, tag_id) do
    Repo.insert(%UserBoardTag{
      tag_id: tag_id,
      user_board_id: user_board_id
    })
  end

  def delete_user_board_tag!(user_board_id, tag_id) do
    Repo.one!(
      from ubt in UserBoardTag,
        where: ubt.user_board_id == ^user_board_id and ubt.tag_id == ^tag_id
    )
    |> Repo.delete!()
  end

  def change_user_board(%UserBoard{} = user_board, attrs \\ %{}) do
    UserBoard.changeset(user_board, attrs)
  end

  def create_user_board(%UserBoard{} = user_board) do
    result = Repo.insert(user_board)
    set_user_board_is_default(result)
    result
  end

  def update_user_board(%UserBoard{} = user_board, params) do
    result =
      user_board
      |> UserBoard.changeset(params)
      |> Repo.update()

    set_user_board_is_default(result)
    result
  end

  defp set_user_board_is_default(%UserBoard{is_default: true} = user_board) do
    UserBoard
    |> where([ub], ub.user_id == ^user_board.user_id and ub.id != ^user_board.id)
    |> Repo.update_all(set: [is_default: false])
  end

  defp set_user_board_is_default({:ok, %UserBoard{} = user_board}) do
    set_user_board_is_default(user_board)
  end

  defp set_user_board_is_default(_) do
    nil
  end

  def delete_user_board!(id) do
    Repo.delete!(%UserBoard{id: Purple.parse_int(id)})
  end

  def item_status_mappings do
    Ecto.Enum.mappings(Item, :status)
  end

  def delete_item!(%Item{} = item) do
    Purple.Uploads.delete_file_uploads_in_item!(item.id)

    Repo.transaction(fn ->
      ItemEntry
      |> where([e], e.item_id == ^item.id)
      |> Repo.delete_all()

      Repo.delete!(item)
    end)
  end
end
