defmodule PurpleWeb.FinanceLive.Helpers do
  @moduledoc """
  Helpers for finance live views
  """
  use PurpleWeb, :verified_routes
  
  def side_nav do
    [
      %{
        label: "Transactions",
        to: ~p"/finance",
        children: [
          %{
            label: "Merchants",
            to: ~p"/finance/merchants",
          },
          %{
            label: "Payment Methods",
            to: ~p"/finance/payment_methods"
          }
        ]
      },
      %{
        label: "Shared Budgets",
        to: ~p"/finance/shared_budgets",
        children:
          for shared_budget <- Purple.Finance.list_shared_budgets() do
            %{
              label: shared_budget.name,
              to: ~p"/finance/shared_budgets/#{shared_budget}"
            }
          end
      }
    ]
  end
end
