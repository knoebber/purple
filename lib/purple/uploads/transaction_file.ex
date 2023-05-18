defmodule Purple.Uploads.TransactionFile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transaction_file_uploads" do
    belongs_to :transaction, Purple.Finance.Transaction
    belongs_to :file_ref, Purple.Uploads.FileRef, foreign_key: :file_upload_id

    timestamps()
  end

  def join_col, do: :transaction_id

  def changeset(file_ref_id, transaction_id) do
    params = %{
      file_upload_id: file_ref_id,
      transaction_id: transaction_id
    }

    %__MODULE__{}
    |> cast(params, [:transaction_id, :file_upload_id])
    |> validate_required([:transaction_id, :file_upload_id])
    |> assoc_constraint(:transaction)
    |> assoc_constraint(:file_ref)
    |> unique_constraint([:transaction_id, :file_ref_id],
      message: "Transaction already has this file uploaded",
      name: "transaction_file_uploads_transaction_id_file_upload_id_index"
    )
  end
end
