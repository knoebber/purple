defmodule Purple.Google do
  import Ecto.Query

  alias Purple.Repo
  alias Purple.Accounts.UserOAuthToken

  @moduledoc """
  Context for interacting with Google.

  Authentication flow:
  1. Get auth code
  2. Trade auth code for access/refresh token
  3. Trade refresh token for new access token

  See: https://developers.google.com/identity/protocols/oauth2/web-server#httprest
  """

  defp client_id do
    Application.fetch_env!(:purple, :oauth_client_id)
  end

  defp client_secret do
    Application.fetch_env!(:purple, :oauth_client_secret)
  end

  @doc """
  Returns a client that can be used to get an auth code from Google.
  """
  def auth_code_client(redirect_uri) do
    OAuth2.Client.new(
      authorize_url: "/o/oauth2/v2/auth",
      client_id: client_id(),
      client_secret: client_secret(),
      params: %{
        "scope" => "https://www.googleapis.com/auth/gmail.readonly",
        "access_type" => "offline"
      },
      redirect_uri: redirect_uri,
      site: "https://accounts.google.com"
    )
  end

  @doc """
  Returns a client that can be used to get an access token/refresh token pair from Google.
  """
  def token_client() do
    OAuth2.Client.new(
      site: "https://oauth2.googleapis.com",
      token_url: "/token"
    )
  end

  @doc """
  Returns a Google URL that will ask the user for consent.
  """
  def get_authorize_url!(redirect_uri) do
    redirect_uri
    |> auth_code_client()
    |> OAuth2.Client.authorize_url!()
  end

  @doc """
  Returns a token response with access and refresh tokens
  """
  def make_token!(redirect_uri, auth_code) do
    OAuth2.Client.get_token!(
      token_client(),
      code: auth_code,
      grant_type: "authorization_code",
      client_id: client_id(),
      client_secret: client_secret(),
      redirect_uri: redirect_uri
    )
  end

  def get_user_token(user_id) do
    UserOAuthToken
    |> where([ut], ut.user_id == ^user_id)
    |> Repo.one()
  end

  def save_token!(token = %OAuth2.AccessToken{}, user_id) do
    Repo.insert!(
      UserOAuthToken.new(
        user_id,
        token.access_token,
        token.refresh_token,
        token.expires_at
      )
    )
  end

  def update_token!(current = %UserOAuthToken{}, token = %OAuth2.AccessToken{}) do
    Repo.update!(
      UserOAuthToken.change_access_token(
        current,
        token.access_token,
        token.expires_at
      )
    )
  end
end
