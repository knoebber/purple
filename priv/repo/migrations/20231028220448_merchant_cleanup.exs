defmodule Purple.Repo.Migrations.MerchantCleanup do
  use Ecto.Migration

  def change do
    drop constraint(:transactions, "transactions_merchant_name_id_fkey")

    alter table(:transactions) do
      remove :merchant_id
      modify :merchant_name_id, references(:merchant_names), null: false
    end
  end
end
