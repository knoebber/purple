defmodule Purple.Tags do
  @moduledoc """
  Functions for parsing and saving tags.
  """

  alias Purple.Repo
  alias Purple.Tags.{ItemTag, RunTag, Tag, MerchantTag, TransactionTag, SharedBudgetAdjustmentTag}

  import Ecto.Query

  def tag_pattern, do: ~r/#([a-zA-Z0-9]{2,})/
  def anchored_tag_pattern, do: ~r/^#([a-zA-Z0-9]{2,})$/

  def extract_tags_from_markdown(content) when is_binary(content) do
    content
    |> Purple.Markdown.extract_eligible_tag_text_from_markdown()
    |> Enum.reduce(
      [],
      fn eligible_text, acc ->
        acc ++ extract_tags(eligible_text)
      end
    )
    |> Enum.uniq()
  end

  def extract_tags(content) when is_binary(content) do
    tag_pattern()
    |> Regex.scan(content)
    |> Enum.flat_map(fn [_, match] -> [String.downcase(match)] end)
    |> Enum.uniq()
  end

  def extract_tags(%Purple.Board.Item{} = item) do
    item.entries
    |> Enum.reduce(
      extract_tags_from_markdown(item.description),
      fn entry, acc ->
        acc ++ extract_tags_from_markdown(entry.content)
      end
    )
    |> Enum.uniq()
  end

  def extract_tags(%{description: description, notes: notes}) do
    Enum.uniq(
      extract_tags_from_markdown(description) ++
        extract_tags_from_markdown(notes)
    )
  end

  def extract_tags(%{description: description}) do
    extract_tags_from_markdown(description)
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
            inserted_at: Purple.utc_now()
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
       when is_atom(module) and
              is_list(tag_diff) and
              is_map(ref_params) do
    Repo.transaction(fn ->
      [
        add: insert_tag_refs(module, tag_diff[:add], ref_params),
        remove: delete_tag_refs(module, tag_diff[:remove])
      ]
    end)
  end

  def sync_tags(module, model, ref_params)
      when is_atom(module) and is_struct(model) and is_map(ref_params) do
    update_tag_refs(module, get_or_create_tags(model) |> diff_tags(model.tags), ref_params)
  end

  def sync_tags(id, :item) do
    item = Purple.Board.get_item!(id, :entries, :tags)
    sync_tags(ItemTag, item, %{item_id: id})
  end

  def sync_tags(id, :run) do
    run = Purple.Activities.get_run!(id, :tags)
    sync_tags(RunTag, run, %{run_id: id})
  end

  def sync_tags(id, :transaction) do
    transaction = Purple.Finance.get_transaction!(id, :tags)
    sync_tags(TransactionTag, transaction, %{transaction_id: id})
  end

  def sync_tags(id, :shared_budget_adjustment) do
    adjustment = Purple.Finance.get_shared_budget_adjustment!(id, :tags)
    sync_tags(SharedBudgetAdjustmentTag, adjustment, %{shared_budget_adjustment_id: id})
  end

  def sync_tags(id, :merchant) do
    merchant = Purple.Finance.get_merchant!(id, :tags)
    sync_tags(MerchantTag, merchant, %{merchant_id: id})
  end

  defp tag_filter_subquery(model, tagnames, join_col) when is_list(tagnames) do
    from(m in model,
      select: ^[join_col],
      join: t in assoc(m, :tag),
      where: t.name in ^Enum.map(tagnames, &String.downcase(&1))
    )
  end

  defp tag_filter_subquery(model, tagname, join_col) do
    from(m in model,
      select: ^[join_col],
      join: t in assoc(m, :tag),
      where: t.name == ^String.downcase(tagname)
    )
  end

  defp apply_tag_filter(query, model, tagname, join_col) do
    where(
      query,
      [parent],
      parent.id in subquery(tag_filter_subquery(model, tagname, join_col))
    )
  end

  def filter_by_tag(query, %{tag: tagname}, :transaction) do
    where(
      query,
      [tx, m],
      tx.id in subquery(tag_filter_subquery(TransactionTag, tagname, :transaction_id)) or
        m.id in subquery(tag_filter_subquery(MerchantTag, tagname, :merchant_id))
    )
  end

  def filter_by_tag(query, %{tag: tagname}, :item) do
    apply_tag_filter(query, ItemTag, tagname, :item_id)
  end

  def filter_by_tag(query, %{tag: tagname}, :run) do
    apply_tag_filter(query, RunTag, tagname, :run_id)
  end

  def filter_by_tag(query, %{tag: tagname}, :merchant) do
    apply_tag_filter(query, MerchantTag, tagname, :merchant_id)
  end

  def filter_by_tag(query, _, _), do: query

  defp list_model_tags(model) when is_atom(model) do
    Repo.all(
      from m in model,
        join: t in assoc(m, :tag),
        select: %{count: count(t.id), id: t.id, name: t.name},
        group_by: t.id,
        order_by: t.name
    )
  end

  def list_tags do
    Repo.all(Tag)
  end

  def list_tags(atom), do: list_tags(atom, %{})
  def list_tags(:item, _), do: list_model_tags(ItemTag)
  def list_tags(:run, _), do: list_model_tags(RunTag)
  def list_tags(:merchant, _), do: list_model_tags(MerchantTag)

  def list_tags(:transaction, %{user_id: user_id}) do
    Repo.all(
      from tags in Tag,
        left_join: mt in MerchantTag,
        on: mt.tag_id == tags.id,
        left_join: tt in TransactionTag,
        on: tt.tag_id == tags.id,
        join: tx in Purple.Finance.Transaction,
        on: tx.id == tt.transaction_id or mt.merchant_id == tx.merchant_id,
        where: tx.user_id == ^user_id,
        group_by: tags.id,
        order_by: tags.name,
        select: %{
          count: count(tx.id, :distinct),
          id: tags.id,
          name: tags.name
        }
    )
  end
end
