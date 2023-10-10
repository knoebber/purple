defmodule Purple.Repo.Migrations.Rainfall do
  use Ecto.Migration

  def change do
    create table(:rainfall) do
      add :millimeters, :float, null: false
      add :timestamp, :naive_datetime, null: false
    end

    create table(:wind) do
      add :mph, :float, null: false
      add :direction_degrees, :int, null: false
      add :timestamp, :naive_datetime, null: false
    end
  end
end
