defmodule Petaller.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "file_uploads" do
    field :path, :string
    field :extension, :string
    field :bytes, :integer
    field :sha_hash, :binary
    field :description, :string, default: ""
    field :image_width, :integer
    field :image_height, :integer

    field :dir, :string, virtual: true
    field :filename, :string, virtual: true
  end

  defp set_file_fields(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        {_, filename} = fetch_field(changeset, :filename)
        {_, dir} = fetch_field(changeset, :dir)
        filename = String.downcase(filename)
        extension = Path.extname(filename)
        path = Path.join(dir, String.replace_suffix(filename, extension, ""))

        changeset
        |> put_change(:extension, extension)
        |> put_change(:path, path)

      _ ->
        changeset
    end
  end

  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :description, :dir])
    |> validate_required([:filename, :dir])
    |> set_file_fields
    |> validate_required([:extension, :path])
  end
end
