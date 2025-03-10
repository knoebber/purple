defmodule Purple.MixProject do
  use Mix.Project

  def project do
    [
      app: :purple,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Purple.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0.1"},
      {:earmark, "~> 1.4.40"},
      {:ecto_dev_logger, "~> 0.7.0", runtime: Mix.env() == :dev},
      {:ecto_psql_extras, "~> 0.7.4"},
      {:ecto_sql, "~> 3.9.0"},
      {:esbuild, "~> 0.5.0", runtime: Mix.env() == :dev},
      {:fast_rss, "~> 0.4.4"},
      {:floki, ">= 0.37.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4.0"},
      {:mail, "~> 0.2"},
      {:mogrify, "~> 0.9.2"},
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1.1"},
      {:heroicons, "~> 0.5"},
      {:httpoison, "~> 1.8.2"},
      {:phoenix_html_helpers, "~>1.0.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 1.0.1"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.3"},
      {:tailwind, "~> 0.2.4", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7.9"},
      {:tzdata, "~> 1.1"},
      {:oauth2, "~> 2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
