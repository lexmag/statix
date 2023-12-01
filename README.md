# Statix

[![CI Status](https://github.com/lexmag/statix/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/lexmag/statix/actions/workflows/ci.yml)
[![Hex Version](https://img.shields.io/hexpm/v/statix.svg "Hex Version")](https://hex.pm/packages/statix)

Statix is an Elixir client for StatsD-compatible servers.
It is focused on speed without sacrificing simplicity, completeness, or correctness.

What makes Statix the fastest library around:

  * direct sending to socket <sup>[[1](#direct-sending)]</sup>
  * caching of the UDP packet header
  * connection pooling to distribute the metric sending
  * diligent usage of [IO lists](http://jlouisramblings.blogspot.se/2013/07/problematic-traits-in-erlang.html)

<sup><a name="direct-sending"></a>[1]</sup> In contrast with process-based clients, Statix has lower memory consumption and higher throughput – Statix v1.0.0 does about __876640__ counter increments per flush:

![Statix](https://www.dropbox.com/s/uijh5i8qgzmd11a/statix-v1.0.0.png?raw=1)

<details>
  <summary>It is possible to measure that yourself.</summary>

  ```elixir
  for _ <- 1..10_000 do
    Task.start(fn ->
      for _ <- 1..10_000 do
        StatixSample.increment("sample", 1)
      end
    end)
  end
  ```

  Make sure you have StatsD server running to get more realistic results.

</details>

See [the documentation](https://hexdocs.pm/statix) for detailed usage information.

## Installation

Add Statix as a dependency to your `mix.exs` file:

```elixir
defp deps() do
  [{:statix, ">= 0.0.0"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## License

This software is licensed under [the ISC license](LICENSE).
