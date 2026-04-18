defmodule Cardian.MixProject do
  use Mix.Project

  def project do
    [
      app: :cardian,
      version: "7.7.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Cardian.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, github: "Kraigie/nostrum", ref: "03b06ba1c5094b83991097b1ce76b5fe2740324c"},
      {:req, "~> 0.5.0"},
      {:nimble_parsec, "~> 1.4"},
      {:ecto_sql, "~> 3.13"},
      {:ecto_sqlite3, "~> 0.22"},
      {:ecto_ulid, "~> 0.3.0"},
      {:opentelemetry, "~> 1.7"},
      # git because of metrics
      {:opentelemetry_experimental,
       github: "open-telemetry/opentelemetry-erlang",
       sparse: "apps/opentelemetry_experimental",
       override: true},
      {:opentelemetry_api, "~> 1.5"},
      {:opentelemetry_api_experimental,
       github: "open-telemetry/opentelemetry-erlang",
       sparse: "apps/opentelemetry_api_experimental",
       override: true},
      {:opentelemetry_exporter, "~> 1.10"}
    ]
  end
end
