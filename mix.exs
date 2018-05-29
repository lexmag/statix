defmodule Statix.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :statix,
      name: "Statix",
      version: "1.1.0",
      elixir: "~> 1.2",
      description: description(),
      package: package(),
      deps: deps(),
    ]
  end

  def application() do
    [applications: [:logger]]
  end

  defp description() do
    "Fast and reliable Elixir client for StatsD-compatible servers."
  end

  defp package() do
    [
      maintainers: ["Aleksei Magusev", "Andrea Leopardi"],
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/lexmag/statix"},
    ]
  end

  defp deps() do
    [{:ex_doc, ">= 0.0.0", only: :docs}]
  end
end
