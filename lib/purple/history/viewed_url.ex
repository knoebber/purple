defmodule Purple.History.ViewedUrl do
  use Ecto.Schema

  schema "viewed_urls" do
    field :url, :string
    field :freshness, :integer

    belongs_to :user, Purple.Accounts.User

    timestamps(updated_at: false)
  end
end
