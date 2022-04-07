defmodule Petaller.Uploads do
  import Ecto.Query, warn: false
  alias Petaller.Repo
  alias Petaller.Uploads.Upload

  defp remove_extname(s), do: String.replace_suffix(s, Path.extname(s), "")
  defp remove_repeating_underscore(s), do: Regex.replace(~r/__+/, s, "_")
  defp remove_non_alphanum(s), do: Regex.replace(~r/[^a-z0-9]/, s, "_")

  def thumb_x, do: 250
  def thumb_y, do: 250
  def upload_dir, do: Application.get_env(:petaller, :upload_dir)

  def get_thumbnail_name(%Upload{} = upload) do
    "file_upload_#{upload.id}_#{thumb_x()}x#{thumb_y()}#{upload.extension}"
  end

  def get_full_upload_path(%Upload{path: path, extension: extension}) do
    Path.join(upload_dir(), path) <> extension
  end

  def get_full_thumbnail_path(%Upload{} = upload) do
    Path.join([upload_dir(), "thumbnails", get_thumbnail_name(upload)])
  end

  def get_file_info(source_path) do
    try do
      # Throws when source_path isn't an image or doesn't exist.
      info = Mogrify.identify(source_path)

      %{
        extension: "." <> info.format,
        image_height: info.height,
        image_width: info.width
      }
    rescue
      MatchError ->
        %{
          extension: Path.extname(source_path),
          image_height: nil,
          image_width: nil
        }
    end
  end

  def hash_file!(source_path) do
    File.stream!(source_path)
    |> Enum.reduce(:crypto.hash_init(:sha), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
  end

  def get_relative_upload_path(dir, client_name) do
    Path.join([
      dir,
      client_name
      |> String.downcase()
      |> remove_extname
      |> remove_non_alphanum
      |> remove_repeating_underscore
    ])
  end

  def write_thumbnail!(%Upload{} = upload) do
    if is_integer(upload.image_height) and is_integer(upload.image_width) do
      path = get_full_thumbnail_path(upload)
      File.mkdir_p!(Path.dirname(path))

      upload
      |> get_full_upload_path
      |> Mogrify.open()
      |> Mogrify.resize_to_fill("#{thumb_x()}x#{thumb_y()}")
      |> Mogrify.save(path: get_full_thumbnail_path(upload))
    end

    upload
  end

  defp cp!(source, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(source, dest)
  end

  defp write_upload!(%Upload{} = upload, source_path) do
    try do
      cp!(source_path, get_full_upload_path(upload))
      upload
    rescue
      e ->
        Repo.delete!(upload)
        reraise(e, __STACKTRACE__)
    end
  end

  def make_upload_params(source_path, dir, client_name, client_size) do
    Map.merge(
      %{
        byte_size: client_size,
        sha_hash: hash_file!(source_path),
        path: get_relative_upload_path(dir, client_name)
      },
      get_file_info(source_path)
    )
  end

  def save_file_upload(source_path, params) do
    case Upload.changeset(%Upload{}, params) |> Repo.insert() do
      {:ok, upload} ->
        upload
        |> write_upload!(source_path)
        |> write_thumbnail!()

        upload

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_upload!(id) do
    Repo.get!(Upload, id)
  end
end
