defmodule PurpleWeb.FinanceLive.FinanceHelpers do
  @moduledoc """
  Helpers for finance live views
  """

  def index_path(params) do
    PurpleWeb.Router.Helpers.finance_index_path(
      PurpleWeb.Endpoint,
      :index,
      Purple.drop_falsey_values(params)
    )
  end

  def index_path do
    index_path(%{})
  end

  def create_transaction_path() do
    PurpleWeb.Router.Helpers.finance_create_transaction_path(PurpleWeb.Endpoint, :create)
  end

  def show_transaction_path(params) do
    PurpleWeb.Router.Helpers.finance_show_transaction_path(
      PurpleWeb.Endpoint,
      :show,
      params
    )
  end

  def show_shared_budget_path(params, action) do
    PurpleWeb.Router.Helpers.finance_show_shared_budget_path(
      PurpleWeb.Endpoint,
      action,
      params
    )
  end

  def shared_budget_index_path do
    PurpleWeb.Router.Helpers.finance_shared_budget_index_path(
      PurpleWeb.Endpoint,
      :index,
      %{}
    )
  end

  def merchant_index_path do
    PurpleWeb.Router.Helpers.finance_merchant_index_path(PurpleWeb.Endpoint, :index)
  end

  def show_merchant_path(params) do
    PurpleWeb.Router.Helpers.finance_show_merchant_path(PurpleWeb.Endpoint, :show, params)
  end

  def payment_method_index_path do
    PurpleWeb.Router.Helpers.finance_payment_method_index_path(PurpleWeb.Endpoint, :index)
  end

  def shared_budget_title(%Purple.Finance.SharedBudget{name: name}) do
    name
  end

  def side_nav do
    [
      %{
        label: "Transactions",
        to: index_path()
      },
      %{
        label: "Create Transaction",
        to: create_transaction_path()
      },
      %{
        label: "Merchants",
        to: merchant_index_path()
      },
      %{
        label: "Payment Methods",
        to: payment_method_index_path()
      },
      %{
        label: "Shared Budgets",
        to: shared_budget_index_path(),
        children:
          for shared_budget <- Purple.Finance.list_shared_budgets() do
            %{
              label: shared_budget_title(shared_budget),
              to: show_shared_budget_path(shared_budget, :show)
            }
          end
      }
    ]
  end
end
