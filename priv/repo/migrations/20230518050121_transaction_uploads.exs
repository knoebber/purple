defmodule Purple.Repo.Migrations.TransactionUploads do
  use Ecto.Migration

  def change do
    create table(:transaction_file_uploads) do
      add :transaction_id, references(:transactions), null: false
      add :file_upload_id, references(:file_uploads, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:transaction_file_uploads, [:transaction_id, :file_upload_id])
  end
end
