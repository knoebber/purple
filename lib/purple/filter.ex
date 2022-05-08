defmodule Purple.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :tag, :string, default: ""
    field :query, :string, default: ""
  end

  def make_filter(attrs) do
    cast(%Purple.Filter{}, attrs, [
      :tag,
      :query
    ])
  end

  def make_tag_select_options(type) when is_atom(type) do
    [
      # Emacs isn't displaying an emoji in below string
      {"🏷 All tags", ""}
      | Enum.map(
          Purple.Tags.list_tags(type),
          fn %{count: count, name: name} -> {"#{name} (#{count})", name} end
        )
    ]
  end
end
