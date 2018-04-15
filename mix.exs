defmodule Wordza.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wordza,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :timex,
        :httpoison,
      ],
      # applications: [:httpoison],
      mod: {Wordza.Application, [
      ]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:comb, github: "tallakt/comb"},
      {:gproc, "~> 0.5.0"},
      {:timex, "~> 3.1"},
      {:httpoison, "~> 1.0"},
      {:poison, "~> 3.1"},
    ]
  end
end
