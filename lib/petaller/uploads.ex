defmodule Petaller.Uploads do
  import Ecto.Query, warn: false
  alias Petaller.Repo
  alias Petaller.Uploads.Upload

  def save_file_upload(source_path, priv_dir, client_name, client_size) do
    hash =
      File.stream!(source_path)
      |> Enum.reduce(:crypto.hash_init(:sha), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()

    changeset =
      Upload.changeset(
        %Upload{},
        %{
          byte_size: client_size,
          dir: priv_dir,
          client_name: client_name,
          sha_hash: hash
        }
      )

    if changeset.valid? do
      basepath = "priv/static/uploads"

      dest =
        Path.join([basepath, Ecto.Changeset.get_change(changeset, :path)]) <>
          Ecto.Changeset.get_change(changeset, :extension)

      File.mkdir_p!(Path.dirname(dest))
      File.cp!(source_path, dest)
      Repo.insert(changeset)
    else
      {:error, changeset}
    end
  end
end
