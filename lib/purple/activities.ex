defmodule Purple.Activities do
  @moduledoc """
  The Activities context.
  """
  import Ecto.Query

  alias Purple.Activities.Run
  alias Purple.Filter
  alias Purple.Repo
  alias Purple.Tags

  defp run_select(query) do
    select_merge(
      query,
      %{
        hours: fragment("COALESCE(seconds/3600, 0)"),
        minutes: fragment("COALESCE((seconds/60) % 60, 0)"),
        minute_seconds: fragment("COALESCE(seconds % 60, 0)")
      }
    )
  end

  defp float_or_0(n) when is_float(n), do: n
  defp float_or_0(_), do: 0.0

  @doc """
  Returns the sum of miles in the current week.
  """
  def sum_miles_in_current_week do
    week_start =
      DateTime.utc_now()
      |> DateTime.shift_zone!(Application.get_env(:purple, :default_tz))
      |> DateTime.to_date()
      |> Date.beginning_of_week()

    Run
    |> where([d], d.date >= ^week_start)
    |> Repo.aggregate(:sum, :miles)
    |> float_or_0
    |> Float.round(2)
  end

  defp run_text_search(query, %{query: q}) do
    case Integer.parse(q) do
      {i, extra} when extra in ["", "."] ->
        where(query, [_], fragment("trunc(miles)") == ^i)

      _ ->
        case Float.parse(q) do
          {f, ""} -> where(query, [_], fragment("round(miles::numeric, 1)") == ^Float.round(f, 1))
          _ -> where(query, [r], ilike(r.description, ^"%#{q}%"))
        end
    end
  end

  defp run_text_search(query, _), do: query

  defp order_runs_by(filter) do
    order_by_string = Filter.current_order_by(filter)

    order_by =
      Enum.find(
        Run.__schema__(:fields),
        &(Atom.to_string(&1) == order_by_string)
      )

    if order_by do
      [{Filter.current_order(filter), order_by}]
    else
      [desc: :date]
    end
  end

  @doc """
  Returns the list of runs.

  ## Examples

      iex> list_runs()
      [%Run{}, ...]

  """
  def list_runs(filter \\ %{}) do
    order_by = order_runs_by(filter)

    Run
    |> run_select
    |> run_text_search(filter)
    |> Tags.filter_by_tag(filter, :run)
    |> order_by(^order_by)
    |> Repo.paginate(filter)
  end

  def sum_miles(filter) do
    Run
    |> run_text_search(filter)
    |> Tags.filter_by_tag(filter, :run)
    |> Repo.aggregate(:sum, :miles)
    |> float_or_0
    |> Float.round(2)
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

  def get_run(id) do
    Run
    |> run_select
    |> Repo.get(id)
  end

  def get_run!(id, :tags) do
    Repo.one!(
      from r in Run,
        left_join: t in assoc(r, :tags),
        where: r.id == ^id,
        preload: [tags: t]
    )
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
