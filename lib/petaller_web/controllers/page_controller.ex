defmodule PetallerWeb.PageController do
  use PetallerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
