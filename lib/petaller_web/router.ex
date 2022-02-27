defmodule PetallerWeb.Router do
  use PetallerWeb, :router

  import PetallerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PetallerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  # Other scopes may use custom stacks.
  # scope "/api", PetallerWeb do
  #   pipe_through :api
  # end
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PetallerWeb.Telemetry
    end
  end

  ## Authentication routes
  scope "/", PetallerWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  ## Protected routes
  scope "/", PetallerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/items/", ItemsController, :index
    post "/items/", ItemsController, :create
    get "/items/:id", ItemsController, :show
    delete "/items/:id", ItemsController, :delete
    put "/items/:id/pin", ItemsController, :pin
    delete "/items/:id/pin", ItemsController, :pin
    post "/items/:id/entry", ItemsController, :create_entry
    put "/items/:id/complete", ItemsController, :update_completed_at
    delete "/items/:id/complete", ItemsController, :update_completed_at
  end

  ## Protected live routes
  scope "/", PetallerWeb do
    pipe_through [:browser]

    live_session :default, on_mount: PetallerWeb.UserAuthLive do
      live "/guess", WrongLive

      live "/runs", RunLive.Index, :index
      live "/runs/new", RunLive.Index, :new
      live "/runs/:id/edit", RunLive.Index, :edit
      live "/runs/:id", RunLive.Show, :show
      live "/runs/:id/show/edit", RunLive.Show, :edit
    end
  end

  ## Unprotected routes
  scope "/", PetallerWeb do
    pipe_through [:browser]

    get "/", PageController, :index
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
