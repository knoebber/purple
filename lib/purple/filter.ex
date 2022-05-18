defmodule Purple.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :merchant, :integer
    field :payment_method, :integer
    field :query, :string, default: ""
    field :tag, :string, default: ""
  end

  def make_filter(attrs) do
    cast(%Purple.Filter{}, attrs, [
      :merchant,
      :payment_method,
      :query,
      :tag
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
