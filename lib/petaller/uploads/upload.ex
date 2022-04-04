defmodule Petaller.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "file_uploads" do
    field :path, :string
    field :extension, :string
    field :byte_size, :integer
    field :sha_hash, :binary
    field :description, :string, default: ""
    field :image_width, :integer
    field :image_height, :integer

    field :dir, :string, virtual: true
    field :client_name, :string, virtual: true

    timestamps()
  end

  defp clean_client_name(client_name, extension) do
    Regex.replace(
      ~r/__+/,
      Regex.replace(
        ~r/[^a-z0-9]/,
        String.replace_suffix(client_name, extension, ""),
        "_"
      ),
      "_"
    )
  end

  defp set_file_fields(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        {_, client_name} = fetch_field(changeset, :client_name)
        {_, dir} = fetch_field(changeset, :dir)

        client_name = String.downcase(client_name)
        extension = Path.extname(client_name)

        path = Path.join(dir, clean_client_name(client_name, extension))

        changeset
        |> put_change(:extension, extension)
        |> put_change(:path, path)

      _ ->
        changeset
    end
  end

  def changeset(upload, attrs) do
    #TODO: sha_hash isn't validating before insert..
    upload
    |> cast(attrs, [
      :byte_size,
      :client_name,
      :description,
      :dir,
      :image_height,
      :image_width,
      :sha_hash
    ])
    |> validate_required([
      :byte_size,
      :client_name,
      :dir,
      :sha_hash
    ])
    |> set_file_fields
    |> validate_required([:extension, :path])
    |> unique_constraint([:extension, :path], message: "A file with path exists")
    |> unique_constraint(:sha_hash, message: "Duplicate file content")
  end
end
