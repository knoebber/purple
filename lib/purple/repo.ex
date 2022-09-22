defmodule Purple.Repo do
  import Ecto.Query

  use Ecto.Repo,
    otp_app: :purple,
    adapter: Ecto.Adapters.Postgres

  def paginate(query, p, l) when is_integer(p) and is_integer(l) and p > 0 and l > 0 do
    query
    |> offset(^((p - 1) * l))
    |> limit(^l)
    |> __MODULE__.all()
  end

  def paginate(query, filter) when is_map(filter) do
    paginate(
      query,
      Purple.Filter.current_page(filter),
      Purple.Filter.current_limit(filter)
    )
  end
end
