defmodule PurpleWeb.FinanceLive.Helpers do
  @reserved_keys [
    "action",
    "id",
    "merchant_id",
    "payment_method_id"
  ]

  def index_path(params, new_params = %{}) do
    PurpleWeb.Router.Helpers.finance_index_path(
      PurpleWeb.Endpoint,
      :index,
      Map.merge(params, new_params)
    )
  end

  def index_path(params, action)
      when action in [
             :new_transaction,
             :new_merchant,
             :new_payment_method
           ] do
    index_path(params, %{action: Atom.to_string(action)})
  end

  def index_path(params, action, id)
      when action in [
             :edit_transaction,
             :edit_merchant,
             :edit_payment_method
           ] do
    index_path(params, %{action: Atom.to_string(action), id: id})
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
