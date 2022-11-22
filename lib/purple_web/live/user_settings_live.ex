defmodule PurpleWeb.UserSettingsLive do
  use PurpleWeb, :live_view

  alias Purple.Accounts

  defp oauth_redirect_uri(socket) do
    IO.inspect(socket, label: "TODO: fix redirect uri")

    if false do
      port = socket.port

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
        ~p"/users/settings"
    end
  end

  def mount(%{"code" => oauth_code}, _, socket) do
    if oauth_code && not socket.assigns.has_google_token do
      case Gmail.make_token(oauth_redirect_uri(socket), oauth_code) do
        {:ok, %{token: token}} ->
          Accounts.save_oauth_token!(token, socket.assigns.current_user.id)
          put_flash(socket, :info, "OAuth token saved.")

        {:error, response} ->
          Logger.error("failed to make google oauth token: " <> inspect(response))
          put_flash(socket, :error, "Failed to save OAuth token")
      end
    end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_changeset, Accounts.change_user_email(user))
      |> assign(:page_title, "User Settings")
      |> assign(:password_changeset, Accounts.change_user_password(user))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("get_oauth_token", _, socket) do
    push_navigate(
      socket,
      external: Gmail.get_authorize_url!(oauth_redirect_uri(socket))
    )
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    email_changeset = Accounts.change_user_email(socket.assigns.current_user, user_params)

    socket =
      assign(socket,
        email_changeset: Map.put(email_changeset, :action, :validate),
        email_form_current_password: password
      )

    {:noreply, socket}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, put_flash(socket, :info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_changeset, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    password_changeset = Accounts.change_user_password(socket.assigns.current_user, user_params)

    {:noreply,
     socket
     |> assign(:password_changeset, Map.put(password_changeset, :action, :validate))
     |> assign(:current_password, password)}
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
        <.form for={:form} phx-submit="get_oauth_token">
          <.button>OAuth</.button>
        </.form>
      <% end %>
    </.section>
    <.section class="lg:w-1/2 md:w-full window mt-2 mb-2 p-4">
      <h2>Change password</h2>
      <.form
        :let={f}
        id="password_form"
        for={@password_changeset}
        action={~p"/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <div class="flex flex-col mb-2">
          <.input field={{f, :email}} type="hidden" value={@current_email} />
          <.input field={{f, :password}} type="password" label="New password" required />
          <.input field={{f, :password_confirmation}} type="password" label="Confirm new password" />
          <.input
            field={{f, :current_password}}
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
