defmodule PurpleWeb.LiveMount do
  @moduledoc """
  Global mount function for live views in purple.
  """

  import Phoenix.LiveView
  import Phoenix.Component
  alias Purple.Accounts

  def on_mount(:default, _, %{"user_token" => user_token} = _session, socket) do
    socket =
      socket
      |> assign(:side_nav, [])
      |> assign_new(
        :current_user,
        fn -> Accounts.get_user_by_session_token(user_token) end
      )

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "users/log_in")}
    end
  end
end
