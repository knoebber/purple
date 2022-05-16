defmodule Purple.Finance do
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}
  alias Purple.Repo
  alias Purple.Tags

  import Ecto.Query

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
    |> Repo.insert()
  end

  def update_payment_method(%PaymentMethod{} = payment_method, params) do
    payment_method
    |> PaymentMethod.changeset(params)
    |> Repo.insert()
  end

  def update_transaction(%Transaction{} = transaction, params) do
    transaction
    |> Transaction.changeset(params)
    |> Repo.insert()
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
    Repo.get!(Transaction, id)
  end

  def get_transaction!(id, :tags) do
    Repo.one!(
      from tx in Transaction,
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

  def list_transactions(filter) do
    Transaction
    |> Tags.filter_by_tag(filter, :transaction)
    |> order_by(desc: :timestamp)
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