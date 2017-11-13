defmodule Exometer.NewrelicReporter.Mixfile do
  use Mix.Project

  def project do
    [app: :exometer_newrelic_reporter,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:httpoison, :logger],
     mod: {Exometer.NewrelicReporter, []}]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:poison, "~> 2.0 or ~> 3.0" },
      {:excoveralls, "~> 0.6", only: :test}
    ]
  end
end
