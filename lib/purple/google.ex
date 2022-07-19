defmodule Purple.Google do
  import Ecto.Query

  alias Purple.Repo

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
  Returns a Google URL that will ask the user for consent.
  """
  def get_authorize_url!(redirect_uri) do
    OAuth2.Client.authorize_url!(
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
    )
  end

  @doc """
  Returns a token response with access and refresh tokens
  """
  def make_token(redirect_uri, auth_code) do
    OAuth2.Client.new(
      site: "https://oauth2.googleapis.com",
      token_url: "/token"
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.get_token(
      code: auth_code,
      grant_type: "authorization_code",
      client_id: client_id(),
      client_secret: client_secret(),
      redirect_uri: redirect_uri
    )
  end
end
