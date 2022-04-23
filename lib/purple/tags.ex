defmodule Purple.Tags do
  alias Purple.Repo
  alias Purple.Tags.Tag

  import Ecto.Query

  def extract_tags(content) do
    Regex.scan(~r/#([a-zA-Z0-9]{2,})/, content)
    |> Enum.flat_map(fn [_, match] -> [String.downcase(match)] end)
    |> Enum.uniq()
  end

  defp diff_tags_kernel([], %{} = old_tag_map, add_list),
    do: [add: add_list, remove: for(t <- Map.values(old_tag_map), do: t)]

  defp diff_tags_kernel([%Tag{} = head | tail], %{} = old_tag_map, add_list) do
    case Map.pop(old_tag_map, head.id) do
      {nil, old_tag_map} -> diff_tags_kernel(tail, old_tag_map, add_list ++ [head])
      {_, old_tag_map} -> diff_tags_kernel(tail, old_tag_map, add_list)
    end
  end

  def diff_tags(new_tags, old_tags) do
    diff_tags_kernel(
      new_tags,
      Enum.reduce(
        old_tags,
        %{},
        fn tag = %Tag{}, acc -> Map.put(acc, tag.id, tag) end
      ),
      []
    )
  end

  def get_or_create_tags(names) do
    existing_tag_map =
      Enum.reduce(
        Tag |> where([t], t.name in ^names) |> Repo.all(),
        %{},
        fn %Tag{} = tag, acc -> Map.put(acc, tag.name, tag) end
      )

    Enum.reduce(
      names,
      [],
      fn name, acc ->
        case Tag.changeset(%{name: name}) do
          %{valid?: false} -> acc
          changeset -> acc ++ [changeset]
        end
      end
    )
    |> Enum.map(fn changeset ->
      case Map.get(existing_tag_map, changeset.changes.name) do
        nil -> Repo.insert!(changeset)
        existing -> existing
      end
    end)
  end

  def insert_tag_refs(model, tags, ref) do
    Repo.insert_all(
      model,
      Enum.map(tags, fn tag ->
        Map.merge(
          %{
            tag_id: tag.id,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          },
          ref
        )
      end),
      on_conflict: :nothing
    )
  end

  def delete_tag_refs(model, tags) do
    Repo.delete_all(from(m in model, where: m.tag_id in ^for(t <- tags, do: t.id)))
  end

  def sync_tag_refs(model, tag_diff, ref) do
    Repo.transaction(fn ->
      [
        add: insert_tag_refs(model, tag_diff[:add], ref),
        remove: delete_tag_refs(model, tag_diff[:remove])
      ]
    end)
  end

  def get_tag_names_in_item(%Purple.Board.Item{} = item) do
    item.entries
    |> Enum.reduce(
      extract_tags(item.description),
      fn entry, acc ->
        acc ++ extract_tags(entry.content)
      end
    )
    |> Enum.uniq()
  end

  def sync_item_tags(item_id) do
    item = Purple.Board.get_item!(item_id, :entries, :tags)
    new_tags = get_or_create_tags(get_tag_names_in_item(item))

    sync_tag_refs(
      Purple.Tags.ItemTag,
      diff_tags(new_tags, item.tags),
      %{item_id: item_id}
    )
  end
end
