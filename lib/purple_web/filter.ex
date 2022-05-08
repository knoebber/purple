defmodule PurpleWeb.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :tag, :string, default: ""
    field :query, :string, default: ""
  end

  def make_filter(attrs) do
    cast(%PurpleWeb.Filter{}, attrs, [
      :tag,
      :query
    ])
  end
end
