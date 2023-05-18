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

  def pdf?(%FileRef{} = file_ref) do
    String.downcase(file_ref.extension) == ".pdf"
  end

  def get_file_info(source_path, client_name) do
    try do
      # Throws when source_path isn't an image or doesn't exist.
      info = Mogrify.identify(source_path)
      format = String.downcase(info.format)

      if format == "pdf" do
        %{extension: ".pdf"}
      else
        %{
          extension: "." <> format,
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

  defp post_process_file(%FileRef{} = file_ref) do
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
    |> Repo.update()
  end

  defp get_or_create_file_upload(params) do
    existing_ref =
      FileRef
      |> where([ref], ref.sha_hash == ^params.sha_hash)
      |> Repo.one()

    case existing_ref do
      nil -> Repo.insert(FileRef.changeset(%FileRef{}, params))
      _ -> {:exists, existing_ref}
    end
  end

  defp get_ref_model(%Item{}), do: ItemFile

  def save_model_association(%FileRef{} = file_ref, %{id: model_id} = model) do
    Repo.insert(get_ref_model(model).changeset(file_ref.id, model_id))
  end

  defp save_file_ref(source_path, params) do
    case get_or_create_file_upload(params) do
      {:ok, file_ref} ->
        file_ref
        |> write_upload!(source_path)
        |> write_thumbnail!()
        |> post_process_file

      {:exists, file_ref} ->
        {:ok, file_ref}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def save_file_upload(source_path, params, model) do
    with {:ok, %FileRef{} = file_ref} <- save_file_ref(source_path, params),
         {:ok, _} <- save_model_association(file_ref, model) do
      {:ok, file_ref}
    else
      {:error, changeset} -> {:error, changeset}
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

  def delete_model_references!(%{id: model_id} = model) do
    model_ref = get_ref_model(model)

    where_clause = [{model_ref.join_col(), model_id}]

    model_ref
    |> where(^where_clause)
    |> Repo.delete_all()

    # file_refs = get_file_refs_by_model(model)
    # todo: cleanup orphaned files by inspecting all references to model.
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

  defp get_file_refs_by_model_query(%{id: model_id} = model) do
    model_ref = get_ref_model(model)

    inner_where = [{model_ref.join_col(), model_id}]

    from(f in FileRef,
      where: f.id in subquery(from(m in model_ref, select: m.file_upload_id, where: ^inner_where))
    )
  end

  def get_file_refs_by_model(model) do
    Repo.all(get_file_refs_by_model_query(model))
  end

  def get_image_refs_by_model(model) do
    get_file_refs_by_model_query(model)
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
