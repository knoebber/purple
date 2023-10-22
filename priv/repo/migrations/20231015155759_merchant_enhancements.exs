defmodule Purple.Repo.Migrations.MerchantEnhancements do
  use Ecto.Migration

  def change do
    create table(:merchant_names) do
      add :name, :citext, null: false
      add :is_primary, :boolean, null: false, default: false
      add :merchant_id, references(:merchants, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:merchant_names, [:name])

    alter table(:merchants) do
      add :category, :string, default: "OTHER", null: false
    end
  end
end
