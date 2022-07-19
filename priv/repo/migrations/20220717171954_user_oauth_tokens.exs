defmodule Purple.Repo.Migrations.UserOauthTokens do
  use Ecto.Migration

  def change do
    create table(:user_oauth_tokens) do
      add :user_id, references(:users), null: false
      add :access_token, :text, null: false
      add :refresh_token, :text, null: false
      add :access_expires_at, :naive_datetime, null: false

      timestamps()
    end

    create unique_index(:user_oauth_tokens, [:user_id])
  end
end
