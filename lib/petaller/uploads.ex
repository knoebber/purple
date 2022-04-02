defmodule Petaller.Uploads do
  import Ecto.Query, warn: false
  alias Petaller.Repo
  alias Petaller.Uploads.Upload

  def change_upload(%Upload{} = upload, attrs \\ %{}) do
    Upload.changeset(upload, attrs)
  end
end
