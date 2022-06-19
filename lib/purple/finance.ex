defmodule Purple.Finance do
  import Ecto.Query

  alias Purple.Finance.{Transaction, Merchant, PaymentMethod, SharedBudget, SharedTransaction}
  alias Purple.Repo
  alias Purple.Tags

  @amount_fragment "CONCAT('$', ROUND(cents/100.00,2))"

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def change_merchant(%Merchant{} = merchant, attrs \\ %{}) do
    Merchant.changeset(merchant, attrs)
  end

  def change_payment_method(%PaymentMethod{} = payment_method, attrs \\ %{}) do
    PaymentMethod.changeset(payment_method, attrs)
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

  def get_payment_method!(id) do
    Repo.get!(PaymentMethod, id)
  end

  def get_transaction!(id) do
    Repo.one!(
      from tx in Transaction,
        select_merge: %{amount: fragment(@amount_fragment)},
        join: m in assoc(tx, :merchant),
        join: pm in assoc(tx, :payment_method),
        where: tx.id == ^id,
        preload: [merchant: m, payment_method: pm]
    )
  end

  def get_transaction!(id, :tags) do
    Repo.one!(
      from tx in Transaction,
        select_merge: %{amount: fragment(@amount_fragment)},
        left_join: t in assoc(tx, :tags),
        where: tx.id == ^id,
        preload: [tags: t]
    )
  end

  def delete_transaction!(%Transaction{} = transaction) do
    Repo.delete!(transaction)
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

  defp user_filter(q, %{user_id: user_id}), do: where(q, [tx, _, _], tx.user_id == ^user_id)
  defp merchant_filter(q, %{merchant: id}), do: where(q, [_, m, _], m.id == ^id)
  defp merchant_filter(q, _), do: q
  defp payment_method_filter(q, %{payment_method: id}), do: where(q, [_, m, pm], pm.id == ^id)
  defp payment_method_filter(q, _), do: q

  def list_transactions(filter \\ %{}) do
    Transaction
    |> select_merge(%{amount: fragment(@amount_fragment)})
    |> join(:inner, [tx], m in assoc(tx, :merchant))
    |> join(:inner, [tx], pm in assoc(tx, :payment_method))
    |> Tags.filter_by_tag(filter, :transaction)
    |> user_filter(filter)
    |> merchant_filter(filter)
    |> payment_method_filter(filter)
    |> transaction_text_search(filter)
    |> order_by(desc: :timestamp)
    |> preload([_, m, pm], merchant: m, payment_method: pm)
    |> Repo.all()
  end

  def list_payment_methods do
    PaymentMethod
    |> order_by(:name)
    |> Repo.all()
  end

  def list_merchants(filter \\ %{}) do
    Merchant
    |> Tags.filter_by_tag(filter, :merchant)
    |> order_by(:name)
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
    Repo.all(
      from shared_budget in SharedBudget,
        join: shared_transaction in assoc(shared_budget, :shared_transactions),
        join: transaction in assoc(shared_transaction, :transaction),
        join: user in assoc(transaction, :user),
        where: shared_budget.id == ^shared_budget_id,
        group_by: [user.email, user.id],
        order_by: [{:desc, fragment("1")}],
        select: %{
          email: user.email,
          total_cents: sum(transaction.cents),
          total_transactions: count(transaction.id),
          user_id: user.id
        }
    )
  end

  def process_shared_budget_user_totals([]) do
    %{max_cents: 0, title: "Empty shared budget", users: []}
  end

  def process_shared_budget_user_totals(shared_budget_user_totals) do
    Enum.reduce(
      shared_budget_user_totals,
      %{
        max_cents: hd(shared_budget_user_totals).total_cents,
        title: shared_budget_user_totals |> Enum.map(& &1.email) |> Enum.join(", "),
        users: []
      },
      fn data, acc ->
        %{
          acc
          | users:
              acc.users ++ [Map.merge(data, %{cents_behind: acc.max_cents - data.total_cents})]
        }
      end
    )
  end

  def create_shared_budget! do
    Repo.insert!(%SharedBudget{})
  end

  def delete_shared_budget!(id) do
    Repo.delete!(%SharedBudget{id: id})
  end

  def create_shared_transaction!(shared_budget_id, transaction_id)
      when is_integer(shared_budget_id) and is_integer(transaction_id) do
    Repo.insert!(%SharedTransaction{
      shared_budget_id: shared_budget_id,
      transaction_id: transaction_id
    })
  end
end
