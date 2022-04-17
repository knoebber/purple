defmodule Purple.Uploads.FileRef do
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

  def changeset(file_ref, attrs) do
    file_ref
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
    |> unique_constraint(
      [:extension, :path],
      message: "a file with path exists",
      name: "file_uploads_path_extension_index"
    )
    |> unique_constraint(:sha_hash, message: "duplicate file content")
  end
end
