defmodule Purple.Repo.Migrations.DropMerchantName do
  use Ecto.Migration

  def change do
    alter table(:merchants) do
      remove :name
    end
  end
end
