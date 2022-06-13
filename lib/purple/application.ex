defmodule Purple.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Purple.Repo,
      # Start the Telemetry supervisor
      PurpleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Purple.PubSub},
      # Start the Endpoint (http/https)
      PurpleWeb.Endpoint
      # Start a worker by calling: Purple.Worker.start_link(arg)
      # {Purple.Worker, arg}
    ]

    Ecto.DevLogger.install(Purple.Repo)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Purple.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PurpleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
