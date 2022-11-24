defmodule PurpleWeb.RunLive.RunHelpers do
  @moduledoc """
  Helpers for run live views
  """
  use PurpleWeb, :verified_routes

  def side_nav do
    [
      %{
        label: "Runs",
        to: ~p"/runs"
      }
    ]
  end
end
