defmodule Purple.Finance do
  import Ecto.Query

  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}
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

  defp transaction_text_search(query, _), do: query

  def list_transactions(filter) do
    Transaction
    |> select_merge(%{amount: fragment(@amount_fragment)})
    |> Tags.filter_by_tag(filter, :transaction)
    |> join(:inner, [tx], m in assoc(tx, :merchant))
    |> join(:inner, [tx], pm in assoc(tx, :payment_method))
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
end
