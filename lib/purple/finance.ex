defmodule Purple.Finance do
  @moduledoc """
  Context for managing finance data.
  """

  require Logger

  import Ecto.Query

  alias Purple.Finance.{
    ImportedTransaction,
    Merchant,
    MerchantName,
    PaymentMethod,
    SharedBudget,
    SharedBudgetAdjustment,
    SharedTransaction,
    Transaction,
    TransactionImportTask
  }

  alias Purple.Filter
  alias Purple.Gmail
  alias Purple.Repo
  alias Purple.Tags
  alias Purple.TransactionParser

  @dollar_amount_fragment "CONCAT('$', ROUND(cents/100.00,2))"
  @yyyy_mm "to_char(\"timestamp\", 'YYYY-MM')"

  defp get_merchant_name(name) do
    Repo.one(
      from(
        mn in MerchantName,
        join: merchant in assoc(mn, :merchant),
        where: mn.name == ^name,
        preload: [merchant: merchant]
      )
    )
  end

  def merge_merchants(%Merchant{} = main, %Merchant{} = to_merge) do
    Repo.transaction(fn ->
      MerchantName
      |> where([mn], mn.merchant_id == ^to_merge.id)
      |> Repo.update_all(set: [merchant_id: main.id, is_primary: false])

      if to_merge.description != "" do
        update_merchant(main, %{
          "description" => main.description <> "\n\n" <> to_merge.description
        })
      end

      Tags.sync_tags(main.id, :merchant)

      Repo.delete!(to_merge)
    end)
  end

  def give_name_to_merchant(%Merchant{id: merchant_id}, name, is_primary \\ false)
      when is_binary(name) do
    case get_merchant_name(name) do
      nil ->
        {:ok, _} =
          Repo.insert(%MerchantName{name: name, is_primary: is_primary, merchant_id: merchant_id})

        {:ok, get_merchant_name(name)}

      %MerchantName{merchant_id: ^merchant_id, is_primary: ^is_primary} = mn ->
        {:ok, mn}

      %MerchantName{} = other_merchant_name
      when merchant_id != other_merchant_name.merchant_id and other_merchant_name.is_primary ->
        {:error, "cannot give away merchant #{other_merchant_name.merchant_id}'s primary name"}

      %MerchantName{} = other_merchant_name ->
        MerchantName
        |> where([mn], mn.id == ^other_merchant_name.id)
        |> Repo.update_all(
          set: [
            is_primary: is_primary,
            merchant_id: merchant_id,
            updated_at: Purple.Date.utc_now()
          ]
        )

        if is_primary do
          MerchantName
          |> where([mn], mn.merchant_id == ^merchant_id and mn.id != ^other_merchant_name.id)
          |> Repo.update_all(set: [is_primary: false, updated_at: Purple.Date.utc_now()])
        end

        {:ok, get_merchant_name(name)}
    end
  end

  defp maybe_set_primary_name(nil), do: nil
  defp maybe_set_primary_name(m), do: Merchant.set_primary_name(m)

  def get_merchant_by_name(name) when is_binary(name) do
    from(m in Merchant,
      join: names in assoc(m, :names),
      where: names.name == ^name,
      preload: [names: names]
    )
    |> Repo.one()
    |> maybe_set_primary_name()
  end

  def get_merchant_name!(id) do
    Repo.get!(MerchantName, id)
  end

  def get_merchant(id) do
    from(m in Merchant,
      join: names in assoc(m, :names),
      where: m.id == ^id,
      preload: [names: names]
    )
    |> Repo.one()
    |> maybe_set_primary_name()
  end

  def get_merchant!(id) do
    %Merchant{} = get_merchant(id)
  end

  def get_merchant!(id, :tags) do
    id
    |> get_merchant!()
    |> Repo.preload(:tags)
  end

  def get_or_create_merchant!(name) when is_binary(name) do
    {:ok, {:ok, merchant_name}} =
      Repo.transaction(fn ->
        {should_name_be_primary, merchant} =
          case get_merchant_by_name(name) do
            nil -> {true, Repo.insert!(%Merchant{})}
            merchant -> {false, merchant}
          end

        give_name_to_merchant(merchant, name, should_name_be_primary)
      end)

    merchant_name
  end

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def change_merchant(%Merchant{} = merchant, attrs \\ %{}) do
    Merchant.changeset(merchant, attrs)
  end

  def change_payment_method(%PaymentMethod{} = payment_method, attrs \\ %{}) do
    PaymentMethod.changeset(payment_method, attrs)
  end

  def change_shared_budget_adjustment(%SharedBudgetAdjustment{} = adjustment, attrs \\ %{}) do
    SharedBudgetAdjustment.changeset(adjustment, attrs)
  end

  def change_shared_transaction(%SharedTransaction{} = stx, attrs \\ %{}) do
    SharedTransaction.changeset(stx, attrs)
  end

  def create_merchant(params) do
    %Merchant{}
    |> Merchant.changeset(params)
    |> Repo.insert()
  end

  def create_payment_method(params) do
    %PaymentMethod{}
    |> PaymentMethod.changeset(params)
    |> Repo.insert()
  end

  def create_transaction(user_id, params) do
    %Transaction{user_id: user_id}
    |> Transaction.changeset(params)
    |> Repo.insert()
  end

  def create_shared_budget_adjustment(shared_budget_id, params) do
    %SharedBudgetAdjustment{shared_budget_id: shared_budget_id}
    |> SharedBudgetAdjustment.changeset(params)
    |> Repo.insert()
  end

  def create_shared_transaction(shared_budget_id, params) do
    %SharedTransaction{shared_budget_id: shared_budget_id}
    |> SharedTransaction.changeset(params)
    |> Repo.insert()
  end

  def get_or_create_payment_method!(name) when is_binary(name) do
    case get_payment_method_by_name(name) do
      nil -> Repo.insert!(%PaymentMethod{name: name})
      pm -> pm
    end
  end

  def update_merchant(%Merchant{} = merchant, params) do
    merchant
    |> Merchant.changeset(params)
    |> Repo.update()
  end

  def update_payment_method(%PaymentMethod{} = payment_method, params) do
    payment_method
    |> PaymentMethod.changeset(params)
    |> Repo.update()
  end

  def update_transaction(%Transaction{} = transaction, params) do
    transaction
    |> Transaction.changeset(params)
    |> Repo.update()
  end

  def update_shared_budget_adjustment(%SharedBudgetAdjustment{} = adjustment, params) do
    adjustment
    |> SharedBudgetAdjustment.changeset(params)
    |> Repo.update()
  end

  def update_shared_transaction(%SharedTransaction{} = stx, params) do
    stx
    |> SharedTransaction.changeset(params)
    |> Repo.update()
  end

  def toggle_show_adjustments(shared_budget_id, should_show) do
    SharedBudget
    |> where([sb], sb.id == ^shared_budget_id)
    |> Repo.update_all(set: [show_adjustments: should_show])
  end

  def get_user_import_task(user_id) do
    Repo.one(from(it in TransactionImportTask, where: it.user_id == ^user_id))
  end

  def get_shared_budget(id) do
    Repo.get!(SharedBudget, id)
  end

  def get_payment_method_by_name(name) when is_binary(name) do
    Repo.one(from(pm in PaymentMethod, where: pm.name == ^name))
  end

  def get_payment_method!(id) do
    Repo.get!(PaymentMethod, id)
  end

  defp get_transaction_query(id) do
    from(tx in Transaction,
      select_merge: %{dollars: fragment(@dollar_amount_fragment)},
      join: m in assoc(tx, :merchant_name),
      join: pm in assoc(tx, :payment_method),
      where: tx.id == ^id,
      preload: [merchant_name: m, payment_method: pm]
    )
  end

  def get_transaction(id) do
    Repo.one(get_transaction_query(id))
  end

  def get_transaction!(id) do
    Repo.one!(get_transaction_query(id))
  end

  def get_transaction!(id, :shared_transaction) do
    Repo.preload(get_transaction(id), :shared_transaction)
  end

  def get_transaction!(id, :tags) do
    Repo.one!(
      from(tx in Transaction,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        left_join: t in assoc(tx, :tags),
        where: tx.id == ^id,
        preload: [tags: t]
      )
    )
  end

  defp shared_budget_adjustment_query(id) do
    from(adjustment in SharedBudgetAdjustment,
      select_merge: %{dollars: fragment(@dollar_amount_fragment)},
      join: u in assoc(adjustment, :user),
      where: adjustment.id == ^id,
      preload: [user: u]
    )
  end

  def get_shared_budget_adjustment(id) do
    Repo.one(shared_budget_adjustment_query(id))
  end

  def get_shared_budget_adjustment!(id) do
    Repo.one!(shared_budget_adjustment_query(id))
  end

  def get_shared_budget_adjustment!(id, :tags) do
    Repo.one!(
      from(adjustment in SharedBudgetAdjustment,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        left_join: t in assoc(adjustment, :tags),
        where: adjustment.id == ^id,
        preload: [tags: t]
      )
    )
  end

  def load_shared_budget_adjustment_user(%SharedBudgetAdjustment{} = adjustment) do
    Repo.preload(adjustment, :user)
  end

  def delete_transaction!(%Transaction{} = transaction) do
    Repo.delete!(transaction)
  end

  def delete_shared_budget_adjustment(%SharedBudgetAdjustment{} = adjustment) do
    Repo.delete!(adjustment)
  end

  def delete_merchant!(%Merchant{} = merchant) do
    Repo.delete!(merchant)
  end

  def delete_payment_method!(%PaymentMethod{} = payment_method) do
    Repo.delete!(payment_method)
  end

  defp transaction_text_search(query, %{query: q}) do
    term = "%#{q}%"

    where(
      query,
      [tx, m, pm],
      ilike(tx.description, ^term) or
        ilike(m.name, ^term) or
        ilike(pm.name, ^term) or
        ilike(tx.category, ^term)
    )
  end

  defp transaction_text_search(q, _), do: q

  defp user_filter(q, %{user_id: user_id}) do
    where(q, [tx], tx.user_id == ^user_id)
  end

  defp month_filter(q, %{month: month}) do
    where(q, [tx], fragment(@yyyy_mm) == ^month)
  end

  defp month_filter(q, _), do: q

  defp category_filter(q, %{category: category}) do
    where(q, [tx], ilike(tx.category, ^category))
  end

  defp category_filter(q, _), do: q

  defp merchant_filter(q, %{merchant_id: merchant_id}) do
    where(
      q,
      [_, mn],
      mn.id in subquery(
        from mn in MerchantName,
          select: [:id],
          join: m in assoc(mn, :merchant),
          where: m.id == ^merchant_id
      )
    )
  end

  defp merchant_filter(q, _), do: q

  defp payment_method_filter(q, %{payment_method_id: id}) do
    where(q, [_, _, pm], pm.id == ^id)
  end

  defp payment_method_filter(q, _), do: q

  defp shared_budget_filter(q, %{shared_budget_id: id}) do
    where(q, [_, _, _, stx], stx.shared_budget_id == ^id)
  end

  defp shared_budget_filter(q, %{not_shared_budget_id: id}) do
    where(q, [_, _, _, stx], is_nil(stx.shared_budget_id) or stx.shared_budget_id != ^id)
  end

  defp shared_budget_filter(q, _), do: q

  defp order_transactions_by(filter) do
    order_by_string = Filter.current_order_by(filter)

    order_by =
      Enum.find(
        Transaction.__schema__(:fields),
        &(Atom.to_string(&1) == order_by_string)
      )

    if order_by do
      [{Filter.current_order(filter), order_by}]
    else
      [desc: :timestamp, desc: :updated_at]
    end
  end

  def list_transactions(filter) do
    order_by = order_transactions_by(filter)

    Transaction
    |> select_merge(%{dollars: fragment(@dollar_amount_fragment)})
    |> join(:inner, [tx], mn in assoc(tx, :merchant_name))
    |> join(:inner, [tx], pm in assoc(tx, :payment_method))
    |> join(:left, [tx], stx in assoc(tx, :shared_transaction))
    |> Tags.filter_by_tag(filter, :transaction)
    |> merchant_filter(filter)
    |> payment_method_filter(filter)
    |> shared_budget_filter(filter)
    |> transaction_text_search(filter)
    |> user_filter(filter)
    |> month_filter(filter)
    |> category_filter(filter)
    |> order_by(^order_by)
    |> preload([_, mn, pm, stx],
      merchant_name: mn,
      payment_method: pm,
      shared_transaction: stx
    )
    |> Repo.paginate(filter)
  end

  def sum_transactions_by_category(filter) do
    query =
      Transaction
      |> join(:inner, [tx], user in assoc(tx, :user))
      |> group_by([tx, user], [user.email, tx.category, fragment(@yyyy_mm)])
      |> select([tx, user], %{
        email: user.email,
        cents: sum(tx.cents),
        category: tx.category,
        month: fragment(@yyyy_mm)
      })
      |> order_by([tx, user], desc: fragment(@yyyy_mm), asc: tx.category, asc: user.email)

    query =
      if Map.has_key?(filter, :user_id) do
        user_filter(query, filter)
      else
        query
      end

    query =
      if Map.has_key?(filter, :category) do
        where(query, [tx], tx.category == ^filter.category)
      else
        query
      end

    Repo.all(query)
  end

  def list_shared_budget_adjustments(filter) do
    sb_filter = fn
      q, %{shared_budget_id: id} -> where(q, [sb], sb.shared_budget_id == ^id)
      q, _ -> q
    end

    SharedBudgetAdjustment
    |> select_merge(%{dollars: fragment(@dollar_amount_fragment)})
    |> join(:inner, [sba], u in assoc(sba, :user))
    |> user_filter(filter)
    |> sb_filter.(filter)
    |> order_by(desc: :inserted_at)
    |> preload([_, u], user: u)
    |> Repo.all()
  end

  def list_payment_methods(user_id) when is_integer(user_id) do
    PaymentMethod
    |> join(:left, [pm], tx in assoc(pm, :transactions))
    |> where([pm, tx], tx.user_id == ^user_id or is_nil(tx.user_id))
    |> order_by(:name)
    |> preload([_, tx], transactions: tx)
    |> Repo.all()
  end

  def list_merchants(user_id) when is_integer(user_id) do
    Merchant
    |> join(:inner, [m], mn in assoc(m, :names))
    |> join(:inner, [_, mn], tx in assoc(mn, :transactions))
    |> where([_, _, tx], tx.user_id == ^user_id)
    |> preload([_, mn], names: mn)
    |> Repo.all()
    |> Enum.map(&Merchant.set_primary_name/1)
    |> Enum.sort(&(&1.primary_name < &2.primary_name))
  end

  def list_merchant_names() do
    MerchantName
    |> order_by(desc: :name)
    |> Repo.all()
  end

  def list_shared_budgets do
    Repo.all(SharedBudget)
  end

  def list_transaction_import_tasks(filter) do
    TransactionImportTask
    |> user_filter(filter)
    |> join(:inner, [ti], u in assoc(ti, :user))
    |> preload([_, u], user: u)
    |> Repo.all()
  end

  defp import_task_filter(q, %{import_task_id: import_task_id}) do
    where(q, [tit], tit.transaction_import_task_id == ^import_task_id)
  end

  defp import_task_filter(q, _), do: q

  def list_imported_transactions(filter) do
    ImportedTransaction
    |> import_task_filter(filter)
    |> Repo.all()
  end

  def payment_method_mappings(user_id) do
    Enum.map(
      list_payment_methods(user_id),
      fn %{id: id, name: name} -> [value: id, key: name] end
    )
  end

  def get_shared_budget_user_totals(shared_budget_id) do
    adjustment_query =
      from(shared_budget in SharedBudget,
        join: adjustment in assoc(shared_budget, :adjustments),
        join: user in assoc(adjustment, :user),
        where: shared_budget.id == ^shared_budget_id,
        group_by: [shared_budget.id, user.email, user.id],
        select: %{
          credit_cents: fragment("SUM(CASE WHEN type = 'CREDIT' THEN cents ELSE 0 END)"),
          shared_cents: fragment("SUM(CASE WHEN type = 'SHARE' THEN cents ELSE 0 END)"),
          email: user.email,
          shared_budget_id: shared_budget.id,
          user_id: user.id
        }
      )

    union_query =
      from(shared_budget in SharedBudget,
        join: shared_transaction in assoc(shared_budget, :shared_transactions),
        join: transaction in assoc(shared_transaction, :transaction),
        join: user in assoc(transaction, :user),
        where: shared_budget.id == ^shared_budget_id,
        group_by: [shared_budget.id, user.email, user.id],
        select: %{
          credit_cents: fragment("SUM(CASE WHEN type = 'CREDIT' THEN cents ELSE 0 END)"),
          shared_cents: fragment("SUM(CASE WHEN type = 'SHARE' THEN cents ELSE 0 END)"),
          email: user.email,
          shared_budget_id: shared_budget.id,
          user_id: user.id
        },
        union_all: ^adjustment_query
      )

    Repo.all(
      from(r in subquery(union_query),
        group_by: [r.shared_budget_id, r.email, r.user_id],
        select: %{
          credit_cents: type(sum(r.credit_cents), :integer),
          shared_cents: type(sum(r.shared_cents), :integer),
          email: r.email,
          shared_budget_id: r.shared_budget_id,
          user_id: r.user_id
        }
      )
    )
  end

  def make_shared_budget_user_data([]) do
    %{max_balance_cents: 0, users: [], user_mappings: []}
  end

  def make_shared_budget_user_data(shared_budget_user_totals) do
    user_totals =
      Enum.map(
        shared_budget_user_totals,
        fn data ->
          Map.merge(
            data,
            %{
              balance_cents:
                trunc(data.credit_cents + data.shared_cents / length(shared_budget_user_totals)),
              transactions:
                list_transactions(%{
                  user_id: data.user_id,
                  shared_budget_id: data.shared_budget_id
                }),
              adjustments:
                list_shared_budget_adjustments(%{
                  user_id: data.user_id,
                  shared_budget_id: data.shared_budget_id
                })
            }
          )
        end
      )
      |> Enum.sort(&(&1.balance_cents >= &2.balance_cents))

    %{
      max_balance_cents: hd(user_totals).balance_cents,
      users: user_totals,
      user_mappings: Enum.map(user_totals, fn data -> [value: data.user_id, key: data.email] end)
    }
  end

  def create_shared_budget!(name) do
    Repo.insert!(%SharedBudget{name: name})
  end

  def delete_shared_budget!(id) do
    Repo.delete!(%SharedBudget{id: id})
  end

  def remove_shared_transaction!(shared_budget_id, transaction_id) do
    Repo.delete!(
      Repo.one(
        from(stx in SharedTransaction,
          where:
            stx.shared_budget_id == ^shared_budget_id and stx.transaction_id == ^transaction_id
        )
      )
    )
  end

  def share_type_mappings do
    Ecto.Enum.mappings(SharedTransaction, :type)
  end

  def category_mappings do
    Enum.map(
      Ecto.Enum.mappings(Transaction, :category),
      fn {value, label} -> {Purple.titleize(label), value} end
    )
  end

  def get_messages_for_import(%TransactionImportTask{user: user} = tit) do
    imported_transactions = list_imported_transactions(%{import_task_id: tit.id})

    case Gmail.list_messages_in_label(user, tit.email_label) do
      {:ok, messages} when is_list(messages) ->
        {:ok,
         Enum.reject(
           messages,
           fn message ->
             Enum.find(imported_transactions, &(&1.data_id == message["id"]))
           end
         )}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_transaction_from_gmail(%TransactionImportTask{user: user} = tit, message_id) do
    with {:ok, message} <- Gmail.get_message(user, message_id),
         {:ok, html} <- TransactionParser.parse_html(Gmail.decode_message_body(message)),
         {:ok, transaction_params} <- TransactionParser.get_params(html, tit.parser) do
      {:ok,
       %{
         transaction_params: Map.put(transaction_params, :user_id, user.id),
         imported_transaction: %ImportedTransaction{
           data_id: message_id,
           data_summary: message["snippet"],
           transaction_import_task_id: tit.id
         }
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def save_imported_transaction(params) when is_map(params) do
    %{
      transaction_params: transaction_params,
      imported_transaction: imported_transaction
    } = params

    Repo.transaction(fn ->
      merchant_name = get_or_create_merchant!(transaction_params.merchant)
      merchant = Repo.preload(merchant_name.merchant, :tags)

      category =
        if merchant.category != :OTHER do
          merchant.category
        else
          Enum.find(
            Ecto.Enum.mappings(Transaction, :category),
            {:OTHER, "OTHER"},
            fn {_, label} ->
              Enum.find(
                merchant.tags,
                fn tag -> String.downcase(label) == String.downcase(tag.name) end
              )
            end
          )
          |> elem(0)
        end

      transaction =
        Repo.insert!(%Transaction{
          cents: transaction_params.cents,
          description: "",
          category: category,
          merchant_name: merchant_name,
          notes: transaction_params.notes,
          payment_method: get_or_create_payment_method!(transaction_params.payment_method),
          timestamp: transaction_params.timestamp,
          user_id: transaction_params.user_id
        })

      imported_transaction =
        Repo.insert!(Map.put(imported_transaction, :transaction_id, transaction.id))

      Logger.info(
        "saved imported transaction: " <>
          "[#{imported_transaction.id}] transaction: [#{transaction.id}]"
      )

      {transaction, imported_transaction}
    end)
  end

  def save_imported_transaction(%TransactionImportTask{} = tit, message_id) do
    case get_transaction_from_gmail(tit, message_id) do
      {:ok, params} -> save_imported_transaction(params)
      {:error, reason} -> {:error, "#{message_id}: #{reason}"}
    end
  end

  def import_transactions(%TransactionImportTask{user: user} = tit) do
    case get_messages_for_import(tit) do
      {:ok, messages} ->
        Logger.info(
          "attempting to import #{length(messages)} transactions for [" <>
            user.email <> "] label [" <> tit.email_label <> "] parser [#{tit.parser}]"
        )

        Enum.map(messages, &save_imported_transaction(tit, &1["id"]))

      {:error, reason} ->
        Logger.error(reason)
        {:error, reason}
    end
  end

  def import_transactions(user_id) when is_integer(user_id) do
    Enum.reduce(
      list_transaction_import_tasks(%{user_id: user_id}),
      %{failed: 0, success: 0, errors: []},
      fn tit, acc ->
        case import_transactions(tit) do
          results when is_list(results) ->
            Enum.reduce(
              results,
              acc,
              fn
                {:ok, _}, acc ->
                  Map.put(acc, :success, acc.success + 1)

                {:error, reason}, acc ->
                  acc
                  |> Map.put(:failed, acc.failed + 1)
                  |> Map.put(:errors, acc.errors ++ [reason])
              end
            )

          {:error, reason} ->
            %{failed: 0, success: 0, error: [reason]}
        end
      end
    )
  end
end
