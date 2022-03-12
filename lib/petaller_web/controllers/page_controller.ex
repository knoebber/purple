defmodule PetallerWeb.PageController do
  use PetallerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", page_title: "Home")
  end
end
