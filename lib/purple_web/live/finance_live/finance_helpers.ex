defmodule PurpleWeb.FinanceLive.FinanceHelpers do
  @reserved_keys [
    "action",
    "id",
    "merchant_id",
    "payment_method_id",
    "transaction_id"
  ]

  def index_path(params, new_params = %{}) do
    PurpleWeb.Router.Helpers.finance_index_path(
      PurpleWeb.Endpoint,
      :index,
      Map.merge(params, new_params)
    )
  end

  def index_path(params, action = :new_transaction) do
    index_path(params, %{action: action})
  end

  def index_path(params, action = :edit_transaction, id) do
    index_path(params, %{action: action, id: id})
  end

  def index_path(params, action, transaction_id \\ nil, id \\ nil)
      when action in [
             :edit_merchant,
             :edit_payment_method,
             :new_merchant,
             :new_payment_method
           ] do
    index_path(
      params,
      Map.filter(%{action: action, id: id, transaction_id: transaction_id}, fn {_, val} ->
        val == action or is_integer(val)
      end)
    )
  end

  def index_path(params) do
    index_path(
      Map.reject(
        params,
        fn {key, val} -> key in @reserved_keys or val == "" end
      ),
      %{}
    )
  end
end
