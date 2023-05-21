defmodule Purple.Repo.Migrations.CreateWeatherSnapshots do
  use Ecto.Migration

  def change do
    create table(:weather_snapshots) do
      add :humidity, :float, null: true
      add :pressure, :float, null: true
      add :temperature, :float, null: true
      add :timestamp, :naive_datetime, null: false
    end
  end
end
