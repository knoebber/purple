defmodule PurpleWeb.UserSettingsController do
  use PurpleWeb, :controller

  alias Purple.Accounts
  alias PurpleWeb.UserAuth

  plug :assign_data

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "oauth"} = params) do
    IO.inspect(conn, label: "conn")
    host = Application.fetch_env!(:purple, PurpleWeb.Endpoint)[:url][:host]
    redirect_uri = "#{conn.scheme}://#{host}:#{conn.port}#{conn.request_path}"

    client =
      OAuth2.Client.new(
        authorize_url: "/o/oauth2/v2/auth",
        client_id: Application.fetch_env!(:purple, :oauth_client_id),
        client_secret: Application.fetch_env!(:purple, :oauth_client_secret),
        params: %{"scope" => "https://www.googleapis.com/auth/gmail.readonly"},
        redirect_uri: redirect_uri,
        site: "https://accounts.google.com",
        strategy: OAuth2.Strategy.AuthCode
      )

    IO.inspect(client, label: "client")
    IO.inspect(OAuth2.Client.authorize_url!(client), label: "url")
    redirect(conn, external: OAuth2.Client.authorize_url!(client))
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_data(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:page_title, "User Settings")
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
