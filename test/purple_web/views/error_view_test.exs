defmodule PurpleWeb.ErrorHTMLTest do
  use PurpleWeb.ConnCase, async: true

  # Bring render_to_string/3 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(PurpleWeb.ErrorHTML, "404", "html", []) =~ "Not found"
  end

  test "renders 500.html" do
    assert render_to_string(PurpleWeb.ErrorHTML, "500", "html", []) =~ "Internal server error"
  end
end
