defmodule Purple.Repo.Migrations.Finance do
  use Ecto.Migration

  def change do
    create table(:merchants) do
      add :name, :string, null: false, size: 255
      add :description, :text, null: false, default: ""

      timestamps()
    end

    create unique_index(:merchants, [:name])

    create table(:payment_methods) do
      add :name, :string, null: false, size: 32

      timestamps()
    end

    create unique_index(:payment_methods, [:name])

    create table(:transactions) do
      add :cents, :int, null: false
      add :timestamp, :naive_datetime, null: false
      add :description, :text, null: false, default: ""

      add :merchant_id, references(:merchants), null: false
      add :payment_method_id, references(:payment_methods), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end

    create table(:transaction_tags) do
      add :transaction_id, references(:transactions, on_delete: :delete_all), null: false
      add :tag_id, references(:tags), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:transaction_tags, [:transaction_id, :tag_id])

    create table(:merchant_tags) do
      add :merchant_id, references(:merchants, on_delete: :delete_all), null: false
      add :tag_id, references(:tags), null: false
      timestamps(updated_at: false)
    end

    create unique_index(:merchant_tags, [:merchant_id, :tag_id])
  end
end
