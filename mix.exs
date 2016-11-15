defmodule Statix.Mixfile do
  use Mix.Project

  def project() do
    [app: :statix,
     version: "0.8.0",
     elixir: "~> 1.2",
     description: description(),
     package: package(),
     deps: deps()]
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

  defp deps() do
    [{:ex_doc, ">= 0.0.0", only: :docs}]
  end
end
