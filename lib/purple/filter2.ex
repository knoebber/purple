defmodule Purple.Filter2 do
  import Ecto.Changeset

  @default_types %{
    query: :string,
    tag: :string,
    page: :integer
  }

  def make_filter(extra_types, data, params)
      when is_map(extra_types) and is_map(data) and is_map(params) do

    types = Map.merge(@default_types, extra_types)
    changeset = cast({data, types}, params, Map.keys(types))

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
