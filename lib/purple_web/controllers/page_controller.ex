defmodule PurpleWeb.PageController do
  use PurpleWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, ":)")
    |> assign(:side_nav, [])
    |> render(:home)
  end
end
