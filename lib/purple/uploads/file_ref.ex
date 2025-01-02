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

    field :file_name, :string, virtual: true
    field :file_title, :string, virtual: true

    many_to_many :items, Purple.Board.Item,
      join_through: Purple.Uploads.ItemFile,
      join_keys: [file_upload_id: :id, item_id: :id]

    timestamps()
  end

  defp remove_extname(s), do: String.replace_suffix(s, Path.extname(s), "")
  defp remove_repeating_underscore(s), do: Regex.replace(~r/__+/, s, "_")
  defp remove_non_alphanum(s), do: Regex.replace(~r/[^a-z0-9]/, s, "_")

  def clean_path(path) when is_binary(path) do
    path
    |> String.downcase()
    |> remove_extname
    |> remove_non_alphanum
    |> remove_repeating_underscore
  end

  def title(%__MODULE__{} = file_ref) do
    Path.basename(file_ref.path <> file_ref.extension)
  end

  def name(%__MODULE__{path: path}) do
    path
    |> String.split("/")
    |> List.last()
  end

  def set_name_and_title(%__MODULE__{} = file_ref) do
    file_ref
    |> Map.put(:title, title(file_ref))
    |> Map.put(:file_name, name(file_ref))
  end

  def size_string(%__MODULE__{byte_size: byte_size}) do
    kb = byte_size / 1000

    if kb < 1000 do
      "#{round(kb)} KB"
    else
      "#{Float.round(byte_size / 1_000_000, 2)} MB"
    end
  end

  defp get_new_path(current_path, new_file_name) do
    parts = String.split(current_path, "/")

    parts
    |> List.replace_at(length(parts) - 1, clean_path(new_file_name))
    |> Enum.join("/")
  end

  defp set_path(changeset) do
    new_file_name = get_change(changeset, :file_name)

    if new_file_name do
      put_change(
        changeset,
        :path,
        get_new_path(
          get_field(changeset, :path),
          new_file_name
        )
      )
    else
      changeset
    end
  end

  def changeset(%__MODULE__{} = file_ref, attrs) do
    file_ref
    |> cast(attrs, [
      :byte_size,
      :extension,
      :file_name,
      :image_height,
      :image_width,
      :path,
      :sha_hash
    ])
    |> set_path()
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
