defmodule PetallerWeb.FileController do
  use PetallerWeb, :controller

  alias Petaller.Uploads
  alias Petaller.Uploads.FileRef

  defp not_found(conn) do
    send_resp(conn, 404, "File reference not found")
  end

  defp get_file_path(id) do
    with %FileRef{} = file_ref <- Uploads.get_file_ref(id) do
      {:ok, Uploads.get_full_upload_path(file_ref)}
    else
      _ -> :error
    end
  end

  defp get_thumbnail_path(id) do
    with %FileRef{} = file_ref <- Uploads.get_file_ref(id) do
      {:ok, Uploads.get_full_thumbnail_path(file_ref)}
    else
      _ -> :error
    end
  end

  def show_thumbnail(conn, %{"id" => id}) do
    with {:ok, path} <- get_thumbnail_path(id) do
      Plug.Conn.send_file(conn, 200, path)
    else
      _ -> not_found(conn)
    end
  end


  def show(conn, %{"id" => id}) do
    with {:ok, path} <- get_file_path(id) do
      Plug.Conn.send_file(conn, 200, path)
    else
      _ -> not_found(conn)
    end
  end

  def download(conn, %{"id" => id}) do
    with {:ok, path} <- get_file_path(id) do
      send_download(conn, {:file, path})
    else
      _ -> not_found(conn)
    end
  end
end
