defmodule PurpleWeb.Router do
  use PurpleWeb, :router
  import Phoenix.LiveDashboard.Router
  import PurpleWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PurpleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  ## Public pages
  scope "/", PurpleWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  ## Live Dashboard
  scope "/" do
    pipe_through [:browser, :require_authenticated_user]

    live_dashboard "/dashboard", metrics: PurpleWeb.Telemetry
  end

  ## Authentication routes
  scope "/", PurpleWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PurpleWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  ## Protected dead routes
  scope "/", PurpleWeb do
    pipe_through [:browser, :require_authenticated_user]
    get "/files/:id", FileController, :show
    get "/files/:id/thumbnail", FileController, :show_thumbnail
    get "/files/:id/download", FileController, :download
  end

  ## Protected live routes
  scope "/", PurpleWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PurpleWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit

      live "/finance", FinanceLive.Index, :index
      live "/finance/transactions/create", FinanceLive.CreateTransaction, :create
      live "/finance/transactions/:id", FinanceLive.ShowTransaction, :show
      live "/finance/merchants", FinanceLive.MerchantIndex, :index
      live "/finance/merchants/:id", FinanceLive.ShowMerchant, :show
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
      live "/runs/create", RunLive.Index, :create
      live "/runs/edit/:id", RunLive.Index, :edit
      live "/runs/:id", RunLive.Show, :show
      live "/runs/:id/edit", RunLive.Show, :edit

      live "/board", BoardLive.Index, :index
      live "/board/settings", BoardLive.BoardSettings, :index
      live "/board/:user_board_id", BoardLive.Index, :index
      live "/board/item/create", BoardLive.CreateItem, :create
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

    get "/", PageController, :home
    delete "/users/log_out", UserSessionController, :delete
  end
end
