defmodule PurpleWeb.UserSettingsController do
  use PurpleWeb, :controller

  require Logger

  alias Purple.Accounts
  alias Purple.Gmail
  alias PurpleWeb.UserAuth

  plug :assign_data

  defp oauth_redirect_uri(conn) do
    port = conn.port

    port =
      if port == 80 do
        ""
      else
        ":#{port}"
      end

    scheme =
      if Application.get_env(:purple, :env) == :dev do
        "http://"
      else
        "https://"
      end

    scheme <>
      Application.fetch_env!(:purple, PurpleWeb.Endpoint)[:url][:host] <>
      port <>
      Routes.user_settings_path(conn, :edit)
  end

  def edit(conn, params) do
    google_code = Map.get(params, "code")
    oauth_redirect_uri(conn)

    if google_code && not conn.assigns.has_google_token do
      case Gmail.make_token(oauth_redirect_uri(conn), google_code) do
        {:ok, %{token: token}} ->
          Accounts.save_oauth_token!(token, conn.assigns.current_user.id)
          redirect(conn, to: Routes.user_settings_path(conn, :edit))

        {:error, response} ->
          Logger.error("failed to make google oauth token: " <> inspect(response))

          conn
          |> put_flash(:error, "Failed to make OAuth token")
          |> render("edit.html")
      end
    else
      render(conn, "edit.html")
    end
  end

  def update(conn, %{"action" => "oauth"}) do
    redirect(
      conn,
      external: Gmail.get_authorize_url!(oauth_redirect_uri(conn))
    )
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
    google_token = Accounts.get_user_oauth_token(user.id)

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:page_title, "User Settings")
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:has_google_token, google_token != nil)
  end
end
