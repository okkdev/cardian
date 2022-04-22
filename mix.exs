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
      {:nostrum,
       git: "https://github.com/Kraigie/nostrum.git",
       ref: "13a3927c872c1540266e9f1ba4bcad4182baa9bf"},
      {:finch, "~> 0.10.2"}
    ]
  end
end
