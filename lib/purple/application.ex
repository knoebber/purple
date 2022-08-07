defmodule Purple.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Purple.Repo,
      PurpleWeb.Telemetry,
      {Phoenix.PubSub, name: Purple.PubSub},
      PurpleWeb.Endpoint,
      Purple.TaskServer
    ]

    if Application.get_env(:purple, :env) == :dev do
      Ecto.DevLogger.install(Purple.Repo)
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.start_link(children, strategy: :one_for_one, name: Purple.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PurpleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
