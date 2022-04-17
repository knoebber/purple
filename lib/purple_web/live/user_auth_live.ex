defmodule PurpleWeb.UserAuthLive do
  import Phoenix.LiveView
  alias Purple.Accounts

  def on_mount(:default, _params, %{"user_token" => user_token} = _session, socket) do
    socket =
      socket
      |> assign_new(
        :current_user,
        fn -> Accounts.get_user_by_session_token(user_token) end
      )

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
