defmodule Petaller.Repo.Migrations.AddFileUploads do
  use Ecto.Migration

  def change do
    create table(:file_uploads) do
      add :path, :string, null: false
      add :extension, :string, null: false
      add :bytes, :bigint, null: false
      add :sha_hash, :binary, null: false
      add :description, :text, null: false, default: ""
      add :image_width, :int
      add :image_height, :int

      timestamps()
    end

    create unique_index(:file_uploads, [:path])
    create unique_index(:file_uploads, [:sha_hash])
  end
end
