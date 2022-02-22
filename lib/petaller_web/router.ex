defmodule PetallerWeb.Router do
  use PetallerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PetallerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PetallerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/items", PetallerWeb do
    pipe_through :browser

    get "/", ItemsController, :index
    post "/", ItemsController, :create
    get "/:id", ItemsController, :show
    delete "/:id", ItemsController, :delete
    put "/:id/pin", ItemsController, :pin
    delete "/:id/pin", ItemsController, :pin
    post "/:id/entry", ItemsController, :create_entry
    put "/:id/complete", ItemsController, :update_completed_at
    delete "/:id/complete", ItemsController, :update_completed_at
  end

  # Other scopes may use custom stacks.
  # scope "/api", PetallerWeb do
  #   pipe_through :api
  # end

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
end
