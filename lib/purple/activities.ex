defmodule Purple.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias Purple.Repo

  alias Purple.Activities.Run

  defp run_select(query) do
    query
    |> select_merge(%{
      hours: fragment("COALESCE(seconds/3600, 0)"),
      minutes: fragment("COALESCE((seconds/60) % 60, 0)"),
      minute_seconds: fragment("COALESCE(seconds % 60, 0)")
    })
  end

  def get_miles_in_week([], _), do: 0

  def get_miles_in_week([%Run{} = head | tail], %Date{} = start_date) do
    if Date.compare(head.date, Date.beginning_of_week(start_date)) == :lt do
      0
    else
      head.miles + get_miles_in_week(tail, start_date)
    end
  end

  @doc """
  Returns the sum of miles in the current week.
  Runs must be ordered by date descending.
  """
  def get_miles_in_current_week(runs) do
    get_miles_in_week(
      runs,
      DateTime.utc_now()
      |> DateTime.shift_zone!(Application.get_env(:purple, :default_tz))
      |> DateTime.to_date()
    )
  end

  @doc """
  Returns the list of runs.

  ## Examples

      iex> list_runs()
      [%Run{}, ...]

  """
  def list_runs do
    Run
    |> run_select
    |> order_by(desc: :date)
    |> Repo.all()
  end

  @doc """
  Gets a single run.
  _
  Raises `Ecto.NoResultsError` if the Run does not exist.

  ## Examples

      iex> get_run!(123)
      %Run{}

      iex> get_run!(456)
      ** (Ecto.NoResultsError)

  """
  def get_run!(id) do
    Run
    |> run_select
    |> Repo.get!(id)
  end

  @doc """
  Creates a run.

  ## Examples

      iex> create_run(%{field: value})
      {:ok, %Run{}}

      iex> create_run(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_run(attrs \\ %{}) do
    %Run{}
    |> Run.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a run.

  ## Examples

      iex> update_run(run, %{field: new_value})
      {:ok, %Run{}}

      iex> update_run(run, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_run(%Run{} = run, attrs) do
    run
    |> Run.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a run.

  ## Examples

      iex> delete_run(run)
      {:ok, %Run{}}

      iex> delete_run(run)
      {:error, %Ecto.Changeset{}}

  """
  def delete_run(%Run{} = run) do
    Repo.delete(run)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking run changes.

  ## Examples

      iex> change_run(run)
      %Ecto.Changeset{data: %Run{}}

  """
  def change_run(%Run{} = run, attrs \\ %{}) do
    Run.changeset(run, attrs)
  end
end
