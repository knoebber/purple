defmodule Purple.Accounts.UserOAuthToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_oauth_tokens" do
    field :access_token, :string
    field :access_expires_at, :naive_datetime
    field :refresh_token, :string

    belongs_to :user, Purple.Accounts.User

    timestamps()
  end

  def new(user_id, access_token, refresh_token, unix_expires_at)
      when is_integer(unix_expires_at) do
    %__MODULE__{
      access_token: access_token,
      access_expires_at: Purple.unix_to_naive(unix_expires_at),
      refresh_token: refresh_token,
      user_id: user_id
    }
  end

  def change_access_token(oauth_token = %__MODULE__{}, access_token, unix_expires_at)
      when is_integer(unix_expires_at) do
    change(
      oauth_token,
      %{
        access_token: access_token,
        access_expires_at: Purple.unix_to_naive(unix_expires_at)
      }
    )
  end
end
