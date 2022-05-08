defmodule Purple.Tags do
  alias Purple.Repo
  alias Purple.Tags.ItemTag
  alias Purple.Tags.RunTag
  alias Purple.Tags.Tag

  import Ecto.Query

  @valid_tag_parents ["p", "li", "h1", "h2", "h3"]

  def valid_tag_parents, do: @valid_tag_parents
  def tag_pattern, do: ~r/#([a-zA-Z0-9]{2,})/
  def anchored_tag_pattern, do: ~r/^#([a-zA-Z0-9]{2,})$/

  def extract_tags_from_earmark_ast(ast) do
    {_, result} =
      Earmark.Transform.map_ast_with(
        ast,
        [],
        fn
          {tag, _, children, _} = node, result when tag in @valid_tag_parents ->
            {
              node,
              Enum.reduce(children, result, fn
                text_leaf, acc when is_binary(text_leaf) -> extract_tags(text_leaf) ++ acc
                _, acc -> acc
              end)
            }

          node, result ->
            {node, result}
        end,
        true
      )

    result
  end

  def extract_tags_from_markdown(md) do
    case EarmarkParser.as_ast(md) do
      {:ok, ast, _} -> extract_tags_from_earmark_ast(ast)
      _ -> []
    end
  end

  def extract_tags(content) when is_binary(content) do
    tag_pattern()
    |> Regex.scan(content)
    |> Enum.flat_map(fn [_, match] -> [String.downcase(match)] end)
    |> Enum.uniq()
  end

  def extract_tags(%Purple.Activities.Run{} = run) do
    extract_tags_from_markdown(run.description)
  end

  def extract_tags(%Purple.Board.Item{} = item) do
    item.entries
    |> Enum.reduce(
      extract_tags(item.description),
      fn entry, acc ->
        acc ++ extract_tags_from_markdown(entry.content)
      end
    )
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

  def get_or_create_tags(names) when is_list(names) do
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

  def get_or_create_tags(model) when is_struct(model), do: get_or_create_tags(extract_tags(model))

  defp insert_tag_refs(_, [], _), do: {0, nil}

  defp insert_tag_refs(module, tags, ref_params) do
    Repo.insert_all(
      module,
      Enum.map(tags, fn tag ->
        Map.merge(
          %{
            tag_id: tag.id,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          },
          ref_params
        )
      end),
      on_conflict: :nothing
    )
  end

  defp delete_tag_refs(_, []), do: {0, nil}

  defp delete_tag_refs(module, tags) do
    Repo.delete_all(from(m in module, where: m.tag_id in ^for(t <- tags, do: t.id)))
  end

  defp update_tag_refs(_, [add: [], remove: []], _), do: {:ok, [add: {0, nil}, remove: {0, nil}]}

  defp update_tag_refs(module, tag_diff, ref_params)
       when is_atom(module) and is_list(tag_diff) and is_map(ref_params) do
    Repo.transaction(fn ->
      [
        add: insert_tag_refs(module, tag_diff[:add], ref_params),
        remove: delete_tag_refs(module, tag_diff[:remove])
      ]
    end)
  end

  def sync_model_tags(module, model, ref_params)
      when is_atom(module) and is_struct(model) and is_map(ref_params),
      do: update_tag_refs(module, get_or_create_tags(model) |> diff_tags(model.tags), ref_params)

  def sync_item_tags(item_id) do
    item = Purple.Board.get_item!(item_id, :entries, :tags)
    sync_model_tags(ItemTag, item, %{item_id: item_id})
  end

  def sync_run_tags(run_id) do
    run = Purple.Activities.get_run!(run_id, :tags)
    sync_model_tags(RunTag, run, %{run_id: run_id})
  end

  def filter_by_tag(query, %{tag: tagname}, :item) do
    apply_tag_filter(query, ItemTag, tagname, :item_id)
  end

  def filter_by_tag(query, %{tag: tagname}, :run) do
    apply_tag_filter(query, RunTag, tagname, :run_id)
  end

  def filter_by_tag(query, _, _), do: query

  defp apply_tag_filter(query, model, tagname, join_col) do
    where(
      query,
      [parent],
      parent.id in subquery(
        from(m in model,
          select: ^[join_col],
          join: t in assoc(m, :tag),
          where: ilike(t.name, ^tagname)
        )
      )
    )
  end

  def list_tags do
    Repo.all(Tag)
  end

  defp list_model_tags(model) when is_atom(model) do
    Repo.all(
      from m in model,
        join: t in assoc(m, :tag),
        select: %{count: count(t.id), id: t.id, name: t.name},
        group_by: t.id,
        order_by: t.name
    )
  end

  def list_tags(:item) do
    list_model_tags(ItemTag)
  end

  def list_tags(:run) do
    list_model_tags(RunTag)
  end
end
