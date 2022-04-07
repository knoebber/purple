defmodule Petaller.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "file_uploads" do
    field :byte_size, :integer
    field :description, :string, default: ""
    field :extension, :string
    field :image_height, :integer
    field :image_width, :integer
    field :path, :string
    field :sha_hash, :binary

    timestamps()
  end

  def changeset(upload, attrs) do
    # TODO: sha_hash isn't validating before insert..
    upload
    |> cast(attrs, [
      :byte_size,
      :extension,
      :image_height,
      :image_width,
      :path,
      :sha_hash
    ])
    |> validate_required([
      :byte_size,
      :extension,
      :path,
      :sha_hash
    ])
    |> unique_constraint([:extension, :path], message: "A file with path exists")
    |> unique_constraint(:sha_hash, message: "Duplicate file content")
  end
end
