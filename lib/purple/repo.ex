defmodule Purple.Repo do
  use Ecto.Repo,
    otp_app: :purple,
    adapter: Ecto.Adapters.Postgres
end
