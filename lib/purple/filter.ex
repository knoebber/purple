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
    limit: :integer,
    order: :string,
    order_by: :string
  }

  defp clean_filter(filter) do
    filter
    |> Purple.drop_falsey_values()
    |> Map.reject(fn {key, val} ->
      is_nil(val) or
        val == "" or
        val == 0 or
        val == false or
        val == [] or
        (key == :page and val == 1) or
        (key == :order_by and Map.get(filter, :order) == "none") or
        (key == :order and val == "none")
    end)
  end

  def make_filter(params, default_params \\ %{}, extra_types \\ %{})
      when is_map(params) and is_map(default_params) and is_map(extra_types) do
    types = Map.merge(@default_types, extra_types)
    changeset = cast({default_params, types}, params, Map.keys(types))

    changeset.data
    |> Map.merge(changeset.changes)
    |> clean_filter()
  end

  def set_default_limit(filter) when is_map(filter) do
    Map.put(filter, :limit, @default_limit)
  end

  def current_limit(filter) when is_map(filter) do
    Map.get(filter, :limit, @default_limit)
  end

  def current_page(filter) when is_map(filter) do
    Map.get(filter, :page, 1)
  end

  def update_page(filter, p) when is_map(filter) and is_integer(p) do
    filter
    |> Map.put(:page, p)
    |> clean_filter()
  end

  def first_page(filter) when is_map(filter) do
    update_page(filter, 1)
  end

  def next_page(filter) when is_map(filter) do
    update_page(filter, current_page(filter) + 1)
  end

  def current_order_by(filter) when is_map(filter) do
    Map.get(filter, :order_by)
  end

  def current_order(filter) when is_map(filter) do
    case Map.get(filter, :order) do
      "desc" -> :desc
      "asc" -> :asc
      _ -> :none
    end
  end

  def current_order(_, nil), do: nil

  def current_order(filter, order_col) when is_map(filter) and is_binary(order_col) do
    if current_order_by(filter) == order_col do
      current_order(filter)
    else
      :none
    end
  end

  def apply_sort(_, nil), do: %{}

  def apply_sort(filter, order_col) when is_map(filter) and is_binary(order_col) do
    filter
    |> Map.put(:order_by, order_col)
    |> Map.put(
      :order,
      case current_order(filter, order_col) do
        :none -> "desc"
        :desc -> "asc"
        :asc -> "none"
      end
    )
    |> first_page()
    |> clean_filter()
  end
end
