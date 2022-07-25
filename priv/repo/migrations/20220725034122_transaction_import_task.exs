defmodule Purple.Repo.Migrations.TransactionImportTask do
  use Ecto.Migration

  def change do
    create table(:transaction_import_tasks) do
      add :user_id, references(:users), null: false
      add :status, :string, null: false
      add :parser, :string, null: false
      add :email_label, :string, null: false

      timestamps()
    end

    create unique_index(:transaction_import_tasks, [:user_id, :parser])

    create table(:imported_transactions) do
      add :transaction_id, references(:transactions, on_delete: :nilify_all), null: true
      add :transaction_import_task_id, references(:transaction_import_tasks), null: false
      add :data_id, :string, null: false

      timestamps()
    end

    create unique_index(:imported_transactions, [:transaction_id])
    create unique_index(:imported_transactions, [:data_id])
  end
end
