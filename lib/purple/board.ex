defmodule Purple.Board do
  @moduledoc """
  Context for managing boards, items, and entries.
  """

  alias Ecto.Changeset
  alias Purple.Board.{ItemEntry, Item, UserBoard, EntryCheckbox}
  alias Purple.Repo
  alias Purple.Tags
  alias Purple.Filter

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

  defp set_empty_item_children(%Item{} = item) do
    Map.put(
      item,
      :entries,
      Enum.map(
        if(is_list(item.entries), do: item.entries, else: []),
        &Map.put(&1, :checkboxes, [])
      )
    )
  end

  def create_item(params) do
    changeset = Item.changeset(%Item{last_active_at: Purple.Date.utc_now()}, params)

    item_transaction(fn ->
      with {:ok, item} <- Repo.insert(changeset),
           {:ok, item} <-
             item
             |> set_empty_item_children()
             |> post_process_item() do
        item
      end
    end)
  end

  def update_item(%Item{} = item, params) do
    changeset = Item.changeset(item, params)

    item_transaction(fn ->
      with {:ok, item} <- Repo.update(changeset),
           {:ok, item} <- post_process_item(item) do
        item
      end
    end)
  end

  def create_item_entry(params, item_id) when is_map(params) and is_integer(item_id) do
    changeset = ItemEntry.changeset(%ItemEntry{item_id: item_id}, params)

    item_transaction(fn ->
      with {:ok, entry} <- Repo.insert(changeset),
           {:ok, entry} <- post_process_entry(Map.put(entry, :checkboxes, []), true) do
        entry
      end
    end)
  end

  def update_item_entry(%ItemEntry{} = entry, params) do
    changeset = ItemEntry.changeset(entry, params)

    item_transaction(fn ->
      with {:ok, entry} <- Repo.update(changeset),
           {:ok, entry} <-
             post_process_entry(
               Repo.preload(entry, :checkboxes),
               changeset.changes != %{}
             ) do
        entry
      end
    end)
  end

  def delete_entry!(%ItemEntry{item_id: item_id} = entry) when is_integer(item_id) do
    item_transaction(fn ->
      entry_has_checkboxes = Repo.exists?(where(EntryCheckbox, [x], x.item_entry_id == ^entry.id))
      Repo.delete!(entry)

      {:ok, _} =
        post_process_entry(
          # FK cascade will cleanup checkboxes. Set them as nil here to avoid attempting to sync.
          Map.put(entry, :checkboxes, nil),
          entry_has_checkboxes
        )

      :ok
    end)
  end

  def get_entry_checkbox_changes(%ItemEntry{id: id} = entry) when is_integer(id) do
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
          EntryCheckbox.changeset(persisted, persisted.is_done)
        else
          EntryCheckbox.changeset(EntryCheckbox.new(entry.id, description))
        end
      end
    )
  end

  defp sync_entry_checkboxes(%ItemEntry{checkboxes: checkboxes} = entry)
       when is_list(checkboxes) do
    changeset =
      entry
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:checkboxes, get_entry_checkbox_changes(entry))

    if changeset.changes == %{} do
      {:noop, entry}
    else
      Repo.update(changeset)
    end
  end

  defp sync_entry_checkboxes(%ItemEntry{} = entry), do: {:noop, entry}

  defp set_item_last_active_at(item_id) do
    last_active_at = Purple.Date.utc_now()

    {1, _} =
      Item
      |> where([i], i.id == ^item_id)
      |> Repo.update_all(set: [last_active_at: last_active_at])

    last_active_at
  end

  defp post_process_item(%Item{} = item) do
    error_tuple_or_nil =
      Enum.find_value(
        if(is_list(item.entries), do: item.entries, else: []),
        fn entry ->
          case sync_entry_checkboxes(entry) do
            {:error, changeset} -> {:error, changeset}
            _ -> nil
          end
        end
      )

    case error_tuple_or_nil do
      nil ->
        {:ok, _} = Purple.Tags.sync_tags(item.id, :item)
        {:ok, Map.put(item, :last_active_at, set_item_last_active_at(item.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  defp post_process_entry(%ItemEntry{} = entry, should_set_last_active_at) do
    {:ok, tag_result} = Purple.Tags.sync_tags(entry.item_id, :item)

    {sync_entry_atom, entry} = sync_entry_checkboxes(entry)

    case sync_entry_atom do
      :error ->
        {:error, entry}

      _ ->
        unless should_set_last_active_at == false and sync_entry_atom == :noop and
                 Tags.noop?(tag_result) do
          set_item_last_active_at(entry.item_id)
        end

        {:ok, entry}
    end
  end

  def get_item(id) do
    Repo.get(Item, id)
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

  def get_entry!(id) do
    Repo.get!(ItemEntry, id)
  end

  def get_entry_checkbox!(id) do
    Repo.get!(EntryCheckbox, id)
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
    |> preload([_, x], checkboxes: x)
    |> Repo.all()
  end

  def set_item_complete!(%Item{} = item, is_complete) do
    now = Purple.Date.utc_now()

    params =
      if is_complete do
        %{
          completed_at: now,
          status: :DONE,
          priority: nil
        }
      else
        %{
          completed_at: nil,
          last_active_at: now,
          status: :TODO,
          priority: 3
        }
      end

    item
    |> Changeset.change(params)
    |> Repo.update!()
  end

  def pin_item!(%Item{} = item, is_pinned) do
    item
    |> Changeset.change(is_pinned: is_pinned)
    |> Repo.update!()
  end

  def collapse_item_entries(entry_ids, is_collapsed) do
    ItemEntry
    |> where([ie], ie.id in ^entry_ids)
    |> Repo.update_all(set: [is_collapsed: is_collapsed])
  end

  def toggle_show_item_files!(%Item{} = item, show_files) do
    item
    |> Changeset.change(show_files: show_files)
    |> Repo.update!()
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

  defp order_items_by(filter) do
    order_by_string = Filter.current_order_by(filter)

    order_by =
      Enum.find(
        Item.__schema__(:fields),
        &(Atom.to_string(&1) == order_by_string)
      )

    if order_by do
      [{Filter.current_order(filter), order_by}]
    else
      [desc: :is_pinned, asc: :priority, desc: :last_active_at]
    end
  end

  def list_items_query(filter \\ %{}) do
    filter =
      if Map.has_key?(filter, :query) do
        filter
        |> Map.merge(%{
          query: filter.query,
          show_done: true,
          tag: ""
        })
        |> Filter.first_page()
        |> Filter.set_default_limit()
      else
        filter
      end

    order_by = order_items_by(filter)

    Item
    |> order_by(^order_by)
    |> item_text_search(filter)
    |> item_done_filter(filter)
    |> Tags.filter_by_tag(filter, :item)
  end

  def list_items(filter \\ %{}) do
    filter
    |> list_items_query()
    |> Repo.paginate(filter)
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

  def set_checkbox_done(checkbox = %EntryCheckbox{id: id}, is_done)
      when is_integer(id) and is_boolean(is_done) do
    checkbox
    |> EntryCheckbox.changeset(is_done)
    |> Repo.update()
  end

  defp get_user_board_query(id) do
    from ub in UserBoard,
      left_join: t in assoc(ub, :tags),
      where: ub.id == ^id,
      preload: [tags: t]
  end

  def get_user_board(id) do
    Repo.one(get_user_board_query(id))
  end

  def get_user_board!(id) do
    Repo.one!(get_user_board_query(id))
  end

  def change_user_board(%UserBoard{} = user_board, attrs \\ %{}) do
    UserBoard.changeset(user_board, attrs)
  end

  def create_user_board(params, user_id) when is_map(params) and is_integer(user_id) do
    %UserBoard{user_id: user_id}
    |> UserBoard.changeset(params)
    |> Repo.insert()
  end

  def update_user_board(%UserBoard{} = user_board, params) do
    user_board
    |> UserBoard.changeset(params)
    |> Repo.update()
  end

  def delete_user_board!(id) when is_binary(id) do
    delete_user_board!(Purple.parse_int!(id))
  end

  def delete_user_board!(id) when is_integer(id) do
    Repo.delete!(%UserBoard{id: id})
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
