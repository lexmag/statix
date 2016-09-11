defmodule Statix.Mixfile do
  use Mix.Project

  def project() do
    [app: :statix,
     version: "0.8.0",
     elixir: "~> 1.0",
     description: description(),
     package: package()]
  end

  def application() do
    [applications: []]
  end

  defp description() do
    "An Elixir client for StatsD compatible servers."
  end

  defp package() do
    [maintainers: ["Aleksei Magusev"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/lexmag/statix"}]
  end
end
