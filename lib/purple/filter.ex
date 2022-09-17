defmodule Purple.Filter do
  @moduledoc """
  Index page for board
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :merchant, :integer
    field :payment_method, :integer
    field :query, :string, default: ""
    field :show_done, :boolean, default: false
    field :tag, :string, default: ""
    field :user_id, :integer
  end

  @deprecated "Migrate to filter2"
  def make_filter(attrs, filter = %Purple.Filter{} \\ %Purple.Filter{}) do
    cast(filter, attrs, [
      :merchant,
      :payment_method,
      :query,
      :show_done,
      :tag
    ])
  end

  @deprecated "Migrate to filter2"
  def clean_filter(changeset = %Ecto.Changeset{}) do
    changeset.data
    |> Map.merge(changeset.changes)
    |> Purple.drop_falsey_values
  end

  @deprecated "Migrate to filter2"
  def make_tag_select_options(type, filter \\ %{}) when is_atom(type) do
    [
      # Emacs isn't displaying an emoji in below string
      {"🏷 All tags", ""}
      | Enum.map(
          Purple.Tags.list_tags(type, filter),
          fn %{count: count, name: name} -> {"#{name} (#{count})", name} end
        )
    ]
  end
end
