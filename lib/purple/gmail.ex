defmodule Purple.Gmail do
  import Ecto.Query

  require Logger

  alias HTTPoison.Response
  alias Purple.Repo
  alias Purple.Accounts
  alias Purple.Accounts.User
  alias Purple.Accounts.UserOAuthToken

  @google_oauth "https://oauth2.googleapis.com"
  @google_accounts "https://accounts.google.com"
  @google_api "https://www.googleapis.com"

  @moduledoc """
  Context for interacting with Gmail.

  Authentication flow:
  1. Get auth code
  2. Trade auth code for access/refresh token
  3. Trade refresh token for new access token

  See: https://developers.google.com/identity/protocols/oauth2/web-server#httprest
  """

  defp gmail_api do
    @google_api <> "/gmail/v1"
  end

  def readonly_scope do
    @google_api <> "/auth/gmail.readonly"
  end

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
          "scope" => readonly_scope(),
          "access_type" => "offline"
        },
        redirect_uri: redirect_uri,
        site: @google_accounts
      )
    )
  end

  @doc """
  Returns a token response with access and refresh tokens
  """
  def make_token(redirect_uri, auth_code) do
    OAuth2.Client.new(
      site: @google_oauth,
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

  def refresh_access_token(refresh_token) do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Refresh,
      client_id: client_id(),
      client_secret: client_secret(),
      site: @google_oauth,
      token_url: "/token",
      params: %{"refresh_token" => refresh_token}
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
    |> OAuth2.Client.get_token()
  end

  def get_user_access_token(user_token = %UserOAuthToken{}) do
    if user_token.access_expires_at < Purple.utc_now() do
      case refresh_access_token(user_token.refresh_token) do
        {:ok, %{token: new_token}} ->
          Logger.info("refreshing token for user #{user_token.user_id}")
          Accounts.update_oauth_token!(user_token, new_token)
          new_token.access_token

        {:error, response} ->
          Logger.error("failed to refresh google oauth token: " <> inspect(response))
          Repo.delete!(user_token)
          nil
      end
    else
      user_token.access_token
    end
  end

  def get_user_access_token(nil) do
    nil
  end

  def get_user_access_token(user_id) when is_integer(user_id) do
    user_id
    |> Accounts.get_user_oauth_token()
    |> get_user_access_token
  end

  defp get_headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp parse_response({:ok, response = %HTTPoison.Response{body: body}})
       when byte_size(body) > 0 do
    if String.contains?(
         response.headers
         |> Enum.into(%{})
         |> Map.get("Content-Type"),
         "application/json"
       ) do
      Jason.decode!(body)
    else
      Logger.error(body)
      {:error, "no json content"}
    end
  end

  defp parse_response({:ok, _}) do
    {:ok, %{}}
  end

  defp parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp get(path, access_token) when is_binary(access_token) do
    uri = gmail_api() <> path
    Logger.info("[gmail request] GET " <> uri)

    uri
    |> HTTPoison.get(get_headers(access_token))
    |> parse_response
  end

  defp get(path, user_id) when is_integer(user_id) do
    case get_user_access_token(user_id) do
      nil -> {:error, "no token found for user #{user_id}"}
      access_token -> get(path, access_token)
    end
  end

  defp build_user_path(user = %User{}, suffix) do
    "/users/#{user.email}" <> suffix
  end

  def list_labels(user = %User{}) do
    user
    |> build_user_path("/labels")
    |> get(user.id)
  end

  def list_messages_in_label(user = %User{}, label_id) do
    user
    |> build_user_path("/messages" <> "?label_ids=#{label_id}")
    |> get(user.id)
  end

  def get_message(user = %User{}, message_id, format \\ "raw") do
    user
    |> build_user_path("/messages/" <> message_id <> "?format=#{format}")
    |> get(user.id)
  end

  def decode_message_body(message) when is_binary(message) do
    message
    |> Base.url_decode64!()
    |> Mail.Encoders.QuotedPrintable.decode
  end

  def decode_message_body(message) when is_map(message) do
    decode_message_body(message["raw"])
  end
end
