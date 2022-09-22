defmodule Purple.Filter do
  @moduledoc """
  Utilities for creating and applying filters to Ecto queries.
  """

  import Ecto.Changeset

  @default_limit 50

  @default_types %{
    query: :string,
    tag: :string,
    page: :integer,
    limit: :integer
  }

  def make_filter(params, default_params \\ %{}, extra_types \\ %{})
      when is_map(params) and is_map(default_params) and is_map(extra_types) do
    types = Map.merge(@default_types, extra_types)
    changeset = cast({default_params, types}, params, Map.keys(types))

    changeset.data
    |> Map.merge(changeset.changes)
    |> Purple.drop_falsey_values()
    |> Map.reject(fn {key, val} ->
      is_nil(val) or
        val == "" or
        val == 0 or
        val == false or
        val == [] or
        (key == :page and val == 1)
    end)
  end

  def current_limit(filter) when is_map(filter) do
    Map.get(filter, :limit, @default_limit)
  end

  def current_page(filter) when is_map(filter) do
    Map.get(filter, :page, 1)
  end

  def update_page(filter, p) when is_map(filter) and is_integer(p) do
    Map.put(filter, :page, p)
  end

  def first_page(filter) when is_map(filter) do
    update_page(filter, 1)
  end

  def next_page(filter) when is_map(filter) do
    update_page(filter, current_page(filter) + 1)
  end
end
