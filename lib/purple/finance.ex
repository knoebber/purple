defmodule Purple.Finance do
  import Ecto.Query

  alias Purple.Finance.{
    Transaction,
    Merchant,
    PaymentMethod,
    SharedBudget,
    SharedTransaction,
    SharedBudgetAdjustment
  }

  alias Purple.Repo
  alias Purple.Tags

  @dollar_amount_fragment "CONCAT('$', ROUND(cents/100.00,2))"

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

  def get_or_create_payment_method!(name) when is_binary(name) do
    case get_payment_method(name) do
      nil -> Repo.insert!(%PaymentMethod{name: name})
      pm -> pm
    end
  end

  def get_or_create_merchant!(name) when is_binary(name) do
    case get_merchant(name) do
      nil -> Repo.insert!(%Merchant{name: name})
      merchant -> merchant
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

  def toggle_show_adjustments(shared_budget_id, should_show) do
    SharedBudget
    |> where([sb], sb.id == ^shared_budget_id)
    |> Repo.update_all(set: [show_adjustments: should_show])
  end

  def get_shared_budget(id) do
    Repo.get!(SharedBudget, id)
  end

  def get_merchant(name) when is_binary(name) do
    Repo.one(from m in Merchant, where: m.name == ^name)
  end

  def get_merchant!(id) do
    Repo.get!(Merchant, id)
  end

  def get_merchant!(id, :tags) do
    Repo.one!(
      from m in Merchant,
        left_join: t in assoc(m, :tags),
        where: m.id == ^id,
        preload: [tags: t]
    )
  end

  def get_payment_method(name) when is_binary(name) do
    Repo.one(from pm in PaymentMethod, where: pm.name == ^name)
  end

  def get_payment_method!(id) do
    Repo.get!(PaymentMethod, id)
  end

  def get_transaction!(id) do
    Repo.one!(
      from tx in Transaction,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        join: m in assoc(tx, :merchant),
        join: pm in assoc(tx, :payment_method),
        where: tx.id == ^id,
        preload: [merchant: m, payment_method: pm]
    )
  end

  def get_transaction!(id, :tags) do
    Repo.one!(
      from tx in Transaction,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        left_join: t in assoc(tx, :tags),
        where: tx.id == ^id,
        preload: [tags: t]
    )
  end

  def get_shared_budget_adjustment!(id) do
    Repo.one!(
      from adjustment in SharedBudgetAdjustment,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        where: adjustment.id == ^id
    )
  end

  def get_shared_budget_adjustment!(id, :tags) do
    Repo.one!(
      from adjustment in SharedBudgetAdjustment,
        select_merge: %{dollars: fragment(@dollar_amount_fragment)},
        left_join: t in assoc(adjustment, :tags),
        where: adjustment.id == ^id,
        preload: [tags: t]
    )
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
        ilike(m.description, ^term) or
        ilike(m.name, ^term) or
        ilike(pm.name, ^term)
    )
  end

  defp transaction_text_search(q, _), do: q

  defp user_filter(q, %{user_id: user_id}), do: where(q, [tx], tx.user_id == ^user_id)
  defp merchant_filter(q, %{merchant: id}), do: where(q, [_, m], m.id == ^id)
  defp merchant_filter(q, _), do: q
  defp payment_method_filter(q, %{payment_method: id}), do: where(q, [_, _, pm], pm.id == ^id)
  defp payment_method_filter(q, _), do: q

  defp shared_budget_filter(q, %{shared_budget_id: id}) do
    where(q, [_, _, _, stx], stx.shared_budget_id == ^id)
  end

  defp shared_budget_filter(q, %{not_shared_budget_id: id}) do
    where(q, [_, _, _, stx], is_nil(stx.shared_budget_id) or stx.shared_budget_id != ^id)
  end

  defp shared_budget_filter(q, _), do: q

  def list_transactions(filter \\ %{}) do
    Transaction
    |> select_merge(%{dollars: fragment(@dollar_amount_fragment)})
    |> join(:inner, [tx], m in assoc(tx, :merchant))
    |> join(:inner, [tx], pm in assoc(tx, :payment_method))
    |> join(:left, [tx], stx in assoc(tx, :shared_transaction))
    |> Tags.filter_by_tag(filter, :transaction)
    |> merchant_filter(filter)
    |> payment_method_filter(filter)
    |> shared_budget_filter(filter)
    |> transaction_text_search(filter)
    |> user_filter(filter)
    |> order_by(desc: :timestamp)
    |> preload([_, m, pm], merchant: m, payment_method: pm)
    |> Repo.all()
  end

  def list_shared_budget_adjustments(filter \\ %{}) do
    sb_filter = fn
      q, %{shared_budget_id: id} -> where(q, [sb], sb.shared_budget_id == ^id)
      q, _ -> q
    end

    SharedBudgetAdjustment
    |> select_merge(%{dollars: fragment(@dollar_amount_fragment)})
    |> join(:inner, [sba], u in assoc(sba, :user))
    |> user_filter(filter)
    |> sb_filter.(filter)
    |> order_by(:inserted_at)
    |> preload([_, u], user: u)
    |> Repo.all()
  end

  def list_payment_methods do
    PaymentMethod
    |> order_by(:name)
    |> Repo.all()
  end

  def list_payment_methods(:transactions) do
    PaymentMethod
    |> join(:left, [pm], tx in assoc(pm, :transactions))
    |> order_by(:name)
    |> preload([_, tx], transactions: tx)
    |> Repo.all()
  end

  def list_merchants() do
    Merchant
    |> order_by(:name)
    |> Repo.all()
  end

  def list_merchants(:transactions) do
    Merchant
    |> join(:left, [m], tx in assoc(m, :transactions))
    |> order_by(:name)
    |> preload([_, tx], transactions: tx)
    |> Repo.all()
  end

  def merchant_mappings do
    Enum.map(
      list_merchants(),
      fn %{id: id, name: name} -> [value: id, key: name] end
    )
  end

  def payment_method_mappings do
    Enum.map(
      list_payment_methods(),
      fn %{id: id, name: name} -> [value: id, key: name] end
    )
  end

  def list_shared_budgets do
    Repo.all(SharedBudget)
  end

  def get_shared_budget_user_totals(shared_budget_id) do
    adjustment_query =
      from shared_budget in SharedBudget,
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

    union_query =
      from shared_budget in SharedBudget,
        join: shared_transaction in assoc(shared_budget, :shared_transactions),
        join: transaction in assoc(shared_transaction, :transaction),
        join: user in assoc(transaction, :user),
        where: shared_budget.id == ^shared_budget_id,
        group_by: [shared_budget.id, user.email, user.id],
        select: %{
          credit_cents: 0,
          shared_cents: sum(transaction.cents),
          email: user.email,
          shared_budget_id: shared_budget.id,
          user_id: user.id
        },
        union_all: ^adjustment_query

    Repo.all(
      from r in subquery(union_query),
        group_by: [r.shared_budget_id, r.email, r.user_id],
        select: %{
          credit_cents: type(sum(r.credit_cents), :integer),
          shared_cents: type(sum(r.shared_cents), :integer),
          email: r.email,
          shared_budget_id: r.shared_budget_id,
          user_id: r.user_id
        }
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

  def create_shared_transaction!(shared_budget_id, transaction_id) do
    Repo.insert!(%SharedTransaction{
      shared_budget_id: shared_budget_id,
      transaction_id: transaction_id
    })
  end

  def remove_shared_transaction!(shared_budget_id, transaction_id) do
    Repo.delete!(
      Repo.one(
        from stx in SharedTransaction,
          where:
            stx.shared_budget_id == ^shared_budget_id and stx.transaction_id == ^transaction_id
      )
    )
  end

  def adjustment_type_mappings do
    Ecto.Enum.mappings(SharedBudgetAdjustment, :type)
  end
end
