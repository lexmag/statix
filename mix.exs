defmodule Statix.Mixfile do
  use Mix.Project

  @name "Statix"
  @version "1.4.0"
  @source_url "https://github.com/lexmag/statix"

  def project() do
    [
      app: :statix,
      version: @version,
      elixir: "~> 1.5",
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: @name,
      docs: docs()
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
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps() do
    [{:ex_doc, "~> 0.20.0", only: :dev}]
  end

  defp docs() do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["CHANGELOG.md"]
    ]
  end
end
