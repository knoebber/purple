defmodule PetallerWeb.ItemsView do
  use PetallerWeb, :view

  def format_date(naive_dt) do
    DateTime.from_naive!(naive_dt, "Etc/UTC")
    |> DateTime.shift_zone!("America/Anchorage")
    |> Calendar.strftime("%m/%d/%Y %I:%M%P")
  end

  def md(markdown) do
    Earmark.as_html!(markdown)
    |> HtmlSanitizeEx.markdown_html
    |> raw
  end
end
