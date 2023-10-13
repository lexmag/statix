defmodule Statix.Mixfile do
  use Mix.Project

  @version "1.4.0"
  @source_url "https://github.com/smartrent/statix"

  def project() do
    [
      app: :statix,
      version: @version,
      elixir: "~> 1.3",
      deps: deps(),

      # Hex
      description: description(),
      package: package(),

      # Docs
      name: "Statix",
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
      main: "Statix",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
