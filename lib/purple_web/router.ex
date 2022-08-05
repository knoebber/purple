defmodule PurpleWeb.Router do
  use PurpleWeb, :router

  import Phoenix.LiveDashboard.Router
  import PurpleWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PurpleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  # Other scopes may use custom stacks.
  # scope "/api", PurpleWeb do
  #   pipe_through :api
  # end
  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through [:browser, :redirect_if_user_not_authenticated]

    live_dashboard "/dashboard", metrics: PurpleWeb.Telemetry
  end

  ## Authentication routes
  scope "/", PurpleWeb do
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
  scope "/", PurpleWeb do
    pipe_through [:browser, :redirect_if_user_not_authenticated]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", PurpleWeb do
    pipe_through [:browser, :require_authenticated_user]
    get "/files/:id", FileController, :show
    get "/files/:id/thumbnail", FileController, :show_thumbnail
    get "/files/:id/download", FileController, :download
  end

  ## Protected live routes
  scope "/", PurpleWeb do
    pipe_through [:browser, :redirect_if_user_not_authenticated]

    live_session :default, on_mount: PurpleWeb.LiveMount do
      live "/finance", FinanceLive.Index, :index
      live "/finance/transactions/:id", FinanceLive.ShowTransaction, :show
      live "/finance/merchants", FinanceLive.MerchantIndex, :index
      live "/finance/payment_methods", FinanceLive.PaymentMethodIndex, :index
      live "/finance/shared_budgets", FinanceLive.SharedBudgetIndex, :index
      live "/finance/shared_budgets/:id", FinanceLive.ShowSharedBudget, :show

      live "/finance/shared_budgets/:id/adjustments/new",
           FinanceLive.ShowSharedBudget,
           :new_adjustment

      live "/finance/shared_budgets/:id/adjustments/edit/:adjustment_id",
           FinanceLive.ShowSharedBudget,
           :edit_adjustment

      live "/runs", RunLive.Index, :index
      live "/runs/:id", RunLive.Show, :show
      live "/runs/:id/edit", RunLive.Show, :edit

      live "/board", BoardLive.Index, :index
      live "/board/settings", BoardLive.BoardSettings, :index
      live "/board/:user_board_id", BoardLive.Index, :index
      live "/board/item/:id", BoardLive.ShowItem, :show
      live "/board/item/:id/edit", BoardLive.ShowItem, :edit_item
      live "/board/item/:id/entry/new", BoardLive.ShowItem, :create_entry
      live "/board/item/:id/entry/:entry_id", BoardLive.ShowItem, :edit_entry
      live "/board/item/:id/files/:file_id", BoardLive.ShowItemFile, :show
      live "/board/item/:id/files", BoardLive.ItemGallery, :index
    end
  end

  ## Unprotected routes
  scope "/", PurpleWeb do
    pipe_through [:browser]

    get "/", PageController, :index
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
