defmodule Petaller.Uploads.ItemFile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_file_uploads" do
    belongs_to :item, Petaller.Board.Item
    belongs_to :file_ref, Petaller.Uploads.FileRef, foreign_key: :file_upload_id

    timestamps()
  end

  def changeset(file_ref_id, item_id) do
    params = %{
      file_upload_id: file_ref_id,
      item_id: item_id
    }

    %Petaller.Uploads.ItemFile{}
    |> cast(params, [:item_id, :file_upload_id])
    |> validate_required([:item_id, :file_upload_id])
    |> assoc_constraint(:item)
    |> assoc_constraint(:file_ref)
  end
end
