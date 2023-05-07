defmodule PurpleWeb.UserSettingsLive do
  alias Purple.Accounts
  alias Purple.Gmail
  use PurpleWeb, :live_view
  require Logger

  defp oauth_redirect_url() do
    make_full_url(~p"/users/settings")
  end

  def mount(%{"code" => oauth_code}, _, socket) do
    google_token = Accounts.get_user_oauth_token(socket.assigns.current_user.id)

    if oauth_code && google_token == nil do
      case Gmail.make_token(oauth_redirect_url(), oauth_code) do
        {:ok, %{token: token}} ->
          Accounts.save_oauth_token!(token, socket.assigns.current_user.id)
          put_flash(socket, :info, "OAuth token saved.")

        {:error, response} ->
          Logger.error("failed to make google oauth token: " <> inspect(response))
          put_flash(socket, :error, "Failed to save OAuth token")
      end
    end

    {:ok, push_navigate(socket, to: ~p"/users/settings", replace: true)}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    google_token = Accounts.get_user_oauth_token(user.id)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_changeset, Accounts.change_user_email(user))
      |> assign(:email_form_current_password, nil)
      |> assign(:has_google_token, google_token != nil)
      |> assign(:page_title, "User Settings")
      |> assign(:password_changeset, Accounts.change_user_password(user))
      |> assign(:side_nav, [])
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("get_oauth_token", _, socket) do
    {:noreply,
     redirect(
       socket,
       external: Gmail.get_authorize_url!(oauth_redirect_url())
     )}
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:trigger_submit, true)
          |> assign(:password_changeset, Accounts.change_user_password(user, user_params))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Settings</h1>

    <.section class="lg:w-1/2 md:w-full mt-2 mb-2 p-4">
      <h2>Gmail API</h2>
      <%= if @has_google_token do %>
        <strong class="text-purple-400">Authorized</strong>
      <% else %>
        <.form for={%{}} phx-submit="get_oauth_token">
          <.button>OAuth</.button>
        </.form>
      <% end %>
    </.section>
    <.section class="lg:w-1/2 md:w-full mt-2 mb-2 p-4">
      <h2>History</h2>
      <.form for={%{}} phx-submit="delete_history" phx-target="#js-side-nav">
        <.button>Delete history</.button>
      </.form>
    </.section>
    <.section class="lg:w-1/2 md:w-full mt-2 mb-2 p-4">
      <h2>Change password</h2>
      <.form
        :let={f}
        id="password_form"
        for={@password_changeset}
        action={~p"/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <div class="flex flex-col mb-2">
          <.input field={f[:email]} type="hidden" value={@current_user.email} />
          <.input field={f[:password]} type="password" label="New password" required />
          <.input field={f[:password_confirmation]} type="password" label="Confirm new password" />
          <.input
            field={f[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
        </div>
        <.button phx-disable-with="Changing...">Change Password</.button>
      </.form>
    </.section>
    """
  end
end
