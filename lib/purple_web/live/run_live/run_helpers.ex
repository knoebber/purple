defmodule PurpleWeb.RunLive.RunHelpers do
  @moduledoc """
  Helpers for run live views
  """

  def index_path(params) do
    PurpleWeb.Router.Helpers.run_index_path(PurpleWeb.Endpoint, :index, params)
  end

  def index_path() do
    index_path(%{})
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
