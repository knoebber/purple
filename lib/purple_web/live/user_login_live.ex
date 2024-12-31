defmodule PurpleWeb.UserLoginLive do
  use PurpleWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)

    {
      :ok,
      socket
      |> assign(:page_title, "Login")
      |> assign(:side_nav, nil)
      |> assign(email: email),
      temporary_assigns: [email: nil]
    }
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:w-1/3">
      <h1>Login</h1>
      <.form
        :let={f}
        for={%{}}
        as={:user}
        id="login_form"
        action={~p"/users/log_in"}
        phx-update="ignore"
      >
        <.input field={f[:email]} type="email" label="Email" required />
        <.input field={f[:password]} type="password" label="Password" required />
        <.button class="mt-2" phx-disable-with="Logging in...">
          Login →
        </.button>
      </.form>
    </div>
    """
  end
end
