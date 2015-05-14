# Statix [![Build Status](https://travis-ci.org/lexmag/statix.svg)](https://travis-ci.org/lexmag/statix)

Statix is an Elixir client for StatsD compatible servers.

## Installation

Add Statix as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:statix]]
end

defp deps() do
  [{:statix, "~> 0.0.1"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## License

This software is licensed under [the ISC license](LICENSE).
