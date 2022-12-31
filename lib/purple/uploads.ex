defmodule Purple.Uploads do
  alias Purple.Board.Item
  alias Purple.Repo
  alias Purple.Uploads.FileRef
  alias Purple.Uploads.ItemFile
  import Ecto.Query
  require Logger

  defp convert_file_type(f = %FileRef{extension: ".heic"}), do: %FileRef{f | extension: ".jpeg"}
  defp convert_file_type(f = %FileRef{}), do: f

  def thumb_format, do: "png"
  def thumb_x, do: 250
  def thumb_y, do: 250
  def upload_dir, do: Application.get_env(:purple, :upload_dir)

  def get_thumbnail_name(%FileRef{id: id}) do
    "file_upload_#{id}_#{thumb_x()}x#{thumb_y()}." <> thumb_format()
  end

  def get_full_upload_path(%FileRef{path: path, extension: extension}) do
    Path.join(upload_dir(), path) <> extension
  end

  def get_full_thumbnail_path(%FileRef{} = file_ref) do
    Path.join([upload_dir(), "thumbnails", get_thumbnail_name(file_ref)])
  end

  def image?(%FileRef{} = file_ref) do
    is_integer(file_ref.image_height) and is_integer(file_ref.image_width)
  end

  def get_file_info(source_path, client_name) do
    try do
      # Throws when source_path isn't an image or doesn't exist.
      info = Mogrify.identify(source_path)

      if info.format == "pdf" do
        %{extension: ".pdf"}
      else
        %{
          extension: "." <> String.downcase(info.format),
          image_height: info.height,
          image_width: info.width
        }
      end
    rescue
      MatchError ->
        %{extension: Path.extname(client_name)}
    end
  end

  def hash_file!(source_path) do
    File.stream!(source_path)
    |> Enum.reduce(:crypto.hash_init(:sha), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
  end

  def get_relative_upload_path(dir, client_name) do
    Path.join([dir, FileRef.clean_path(client_name)])
  end

  def write_thumbnail!(%FileRef{} = file_ref) do
    if image?(file_ref) do
      path = get_full_thumbnail_path(file_ref)
      File.mkdir_p!(Path.dirname(path))

      file_ref
      |> get_full_upload_path
      |> Mogrify.open()
      |> Mogrify.format(thumb_format())
      |> Mogrify.resize_to_fill("#{thumb_x()}x#{thumb_y()}")
      |> Mogrify.auto_orient()
      |> Mogrify.save(path: get_full_thumbnail_path(file_ref))
    end

    file_ref
  end

  defp cp!(source, dest) do
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(source, dest)
  end

  defp write_upload!(%FileRef{} = file_ref, source_path) do
    try do
      cp!(source_path, get_full_upload_path(file_ref))
      file_ref
    rescue
      e ->
        Repo.delete!(file_ref)
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
      get_file_info(source_path, client_name)
    )
  end

  defp post_process_file!(%FileRef{} = file_ref) do
    converted = convert_file_type(file_ref)

    if image?(file_ref) do
      is_extension_changed = converted.extension != file_ref.extension

      original_path = get_full_upload_path(file_ref)
      img = Mogrify.open(original_path)

      if is_extension_changed do
        Mogrify.format(img, String.trim(converted.extension, "."))
      else
        img
      end
      |> Mogrify.auto_orient()
      |> Mogrify.save(in_place: true)

      if is_extension_changed do
        File.rm!(original_path)
      end
    end

    params =
      converted
      |> Map.from_struct()
      |> Map.put(:byte_size, File.stat!(get_full_upload_path(converted)).size)

    file_ref
    |> FileRef.changeset(params)
    |> Repo.update!()
  end

  def save_file_upload(source_path, params) do
    case Repo.insert(FileRef.changeset(%FileRef{}, params)) do
      {:ok, file_ref} ->
        file_ref
        |> write_upload!(source_path)
        |> write_thumbnail!()
        |> post_process_file!

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp delete_file(path) do
    Logger.info("rm " <> path)
    File.rm(path)
  end

  def delete_file_upload!(%FileRef{} = file_ref) do
    delete_file(get_full_upload_path(file_ref))

    if image?(file_ref) do
      delete_file(get_full_thumbnail_path(file_ref))
    end

    Repo.delete!(file_ref)
  end

  def delete_file_upload!(id) do
    id
    |> get_file_ref!
    |> delete_file_upload!
  end

  def delete_file_uploads_in_item!(item_id) do
    Enum.each(get_files_by_item(item_id), fn file ->
      delete_file_upload!(file)
    end)
  end

  def add_file_to_item!(%FileRef{} = file_ref, %Item{} = item) do
    Repo.insert!(ItemFile.changeset(file_ref.id, item.id))
  end

  defp set_file_name(file_ref) do
    Map.put(file_ref, :file_name, FileRef.name(file_ref))
  end

  def get_file_ref(id) do
    FileRef |> Repo.get(id) |> set_file_name()
  end

  def get_file_ref!(id) do
    FileRef |> Repo.get!(id) |> set_file_name()
  end

  defp get_files_by_item_query(item_id) do
    from(f in FileRef,
      where:
        f.id in subquery(
          from(i in ItemFile, select: i.file_upload_id, where: i.item_id == ^item_id)
        )
    )
  end

  def get_files_by_item(item_id) do
    Repo.all(get_files_by_item_query(item_id))
  end

  def get_images_by_item(item_id) do
    get_files_by_item_query(item_id)
    |> where([f], f.image_width > 0)
    |> Repo.all()
  end

  def change_file_ref(%FileRef{} = file_ref, attrs \\ %{}) do
    FileRef.changeset(file_ref, attrs)
  end

  def update_file_ref(%FileRef{} = file_ref, attrs) do
    {_, result} =
      Repo.transaction(fn ->
        update_result =
          file_ref
          |> FileRef.changeset(attrs)
          |> Repo.update()

        if match?({:ok, _}, update_result) do
          {_, updated_file_ref} = update_result

          if updated_file_ref.path != file_ref.path do
            # Rollback db operation if file rename fails
            File.rename!(get_full_upload_path(file_ref), get_full_upload_path(updated_file_ref))
          end

          update_result
        else
          Repo.rollback(update_result)
        end
      end)

    result
  end
end
