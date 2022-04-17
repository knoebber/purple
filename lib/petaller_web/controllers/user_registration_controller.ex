defmodule PetallerWeb.UserRegistrationController do
  use PetallerWeb, :controller

  alias Petaller.Accounts
  alias Petaller.Accounts.User
  alias PetallerWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  defp create_user(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create(conn, params) do
    if Application.get_env(:petaller, :allow_user_registration) do
      create_user(conn, params)
    else
      conn
      |> put_flash(:error, "User registration is disabled")
      |> render("new.html", changeset: Accounts.change_user_registration(%User{}))
    end
  end
end
