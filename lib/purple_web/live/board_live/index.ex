defmodule PurpleWeb.BoardLive.Index do
  @moduledoc """
  Index page for board
  """
  alias Purple.Board
  import PurpleWeb.BoardLive.Helpers
  use PurpleWeb, :live_view

  defp assign_data(socket) do
    assign(socket, :page_title, "Boards")
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {
      :noreply,
      socket
      |> assign_data()
    }
  end

  @impl Phoenix.LiveView
  def mount(_, _, socket) do
    {:ok, assign_side_nav(socket)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @page_title %></h1>
    Items :) WIP
    """
  end
end
