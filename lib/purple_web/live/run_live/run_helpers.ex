defmodule PurpleWeb.RunLive.RunHelpers do
  @moduledoc """
  Helpers for run live views
  """
  use PurpleWeb, :verified_routes

  def index_path(params) do
    ~p"/runs?#{params}"
  end

  def index_path() do
    ~p"/runs"
  end

  def side_nav do
    [
      %{
        label: "Runs",
        to: index_path()
      }
    ]
  end
end
