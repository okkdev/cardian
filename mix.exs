defmodule Cardian.MixProject do
  use Mix.Project

  def project do
    [
      app: :cardian,
      version: "0.1.0",
      elixir: "~> 1.12",
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
      {:nostrum, "~> 0.9.1"},
      {:req, "~> 0.5.0"},
      {:nimble_parsec, "~> 1.2"},
      {:sentry, "~> 10.0"},
      {:finch, "~> 0.18"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:ecto_ulid, "~> 0.3.0"}
    ]
  end
end
