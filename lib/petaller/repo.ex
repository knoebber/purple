defmodule Petaller.Repo do
  use Ecto.Repo,
    otp_app: :petaller,
    adapter: Ecto.Adapters.Postgres
end
