defmodule Purple.Weather do
  @moduledoc """
  The Weather context.
  """

  @in_per_mm 0.03937007874

  import Ecto.Query, warn: false
  alias Purple.Repo

  alias Purple.Weather.{Rainfall, WeatherSnapshot, Wind}

  @doc """
  Returns the list of weather_snapshots.

  ## Examples

      iex> list_weather_snapshots()
      [%WeatherSnapshot{}, ...]

  """
  def list_weather_snapshots do
    Repo.all(WeatherSnapshot)
  end

  @doc """
  Gets a single weather_snapshot.

  Raises `Ecto.NoResultsError` if the Weather snapshot does not exist.

  ## Examples

      iex> get_weather_snapshot!(123)
      %WeatherSnapshot{}

      iex> get_weather_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_weather_snapshot!(id), do: Repo.get!(WeatherSnapshot, id)

  @doc """
  Creates a weather_snapshot.

  ## Examples

      iex> create_weather_snapshot(%{field: value})
      {:ok, %WeatherSnapshot{}}

      iex> create_weather_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_weather_snapshot(attrs \\ %{}) do
    %WeatherSnapshot{}
    |> WeatherSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a weather_snapshot.

  ## Examples

      iex> update_weather_snapshot(weather_snapshot, %{field: new_value})
      {:ok, %WeatherSnapshot{}}

      iex> update_weather_snapshot(weather_snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_weather_snapshot(%WeatherSnapshot{} = weather_snapshot, attrs) do
    weather_snapshot
    |> WeatherSnapshot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a weather_snapshot.

  ## Examples

      iex> delete_weather_snapshot(weather_snapshot)
      {:ok, %WeatherSnapshot{}}

      iex> delete_weather_snapshot(weather_snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_weather_snapshot(%WeatherSnapshot{} = weather_snapshot) do
    Repo.delete(weather_snapshot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking weather_snapshot changes.

  ## Examples

      iex> change_weather_snapshot(weather_snapshot)
      %Ecto.Changeset{data: %WeatherSnapshot{}}

  """
  def change_weather_snapshot(%WeatherSnapshot{} = weather_snapshot, attrs \\ %{}) do
    WeatherSnapshot.changeset(weather_snapshot, attrs)
  end

  def save_rainfall(attrs) do
    attrs
    |> Rainfall.changeset()
    |> Repo.insert()
  end

  def save_wind(attrs) do
    attrs
    |> Wind.changeset()
    |> Repo.insert()
  end

  def get_total_rainfall_inches do
    mm = Repo.one!(from r in Rainfall, select: sum(r.millimeters))
    Float.round((mm || 0) * @in_per_mm, 2)
  end
end
