defmodule Purple.Finance do
  alias Purple.Finance.{Transaction, Merchant, PaymentMethod}
  alias Purple.Repo

  import Ecto.Query

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

  def create_transaction(params) do
    %Transaction{}
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

  def update_transaction(%Transaction{} = tx, params) do
    tx
    |> Transaction.changeset(params)
    |> Repo.insert()
  end

  def get_merchant!(id) do
    Repo.get!(Merchant, id)
  end

  def get_payment_method!(id) do
    Repo.get!(PaymentMethod, id)
  end

  def get_transaction!(id) do
    Repo.get!(Transaction, id)
  end

  def list_transactions(filter) do
    Transaction
    |> Tags.filter_by_tag(filter, :tx)
    |> order_by(desc: :date)
    |> Repo.all()
  end

  def list_payment_methods do
    PaymentMethod
    |> order_by(:name)
    |> Repo.all()
  end

  def list_merchants(filter) do
    Merchant
    |> Tags.filter_by_tag(filter, :merchant)
    |> order_by(desc: :date)
    |> Repo.all()
  end
end
