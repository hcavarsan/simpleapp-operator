defmodule HenriqueOperator.MixProject do
  use Mix.Project

  def project do
    [
      app: :henrique_operator,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bonny, "~> 0.4"},
      {:httpoison, "~> 1.4"},
      {:poison, "~> 4.0"}
    ]
  end
end
