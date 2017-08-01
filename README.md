# Statix

[![Build Status](https://travis-ci.com/lexmag/statix.svg?branch=master)](https://travis-ci.com/lexmag/statix)
[![Hex Version](https://img.shields.io/hexpm/v/statix.svg "Hex Version")](https://hex.pm/packages/statix)

Statix is an Elixir client for StatsD-compatible servers.
It is focused on _speed_ without sacrificing _simplicity_, _completeness_, or _correctness_.

What makes Statix the fastest library around:

  * direct sending to the socket <sup>[[1](#direct-sending)]</sup>
  * caching of the UDP packets header
  * usage of [IO lists](http://jlouisramblings.blogspot.se/2013/07/problematic-traits-in-erlang.html)

<sup><a name="direct-sending"></a>[1]</sup> In contrast with process-based clients, Statix has lower memory consumption and higher throughput – Statix v1.0.0 does about __876640__ counter increments per flush:

![Statix](https://www.dropbox.com/s/uijh5i8qgzmd11a/statix-v1.0.0.png?raw=1)

<details>
  <summary>It is possible to measure it yourself.</summary>

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

## Installation

Add Statix as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:statix]]
end

defp deps() do
  [{:statix, ">= 0.0.0"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

A module that uses Statix becomes a socket connection:

```elixir
defmodule MyApp.Statix do
  use Statix
end
```

Before using connection the `connect/0` function needs to be invoked.
In general, this function is called when your application starts (for example, in its `start/2` callback):

```elixir
def start(_type, _args) do
  :ok = MyApp.Statix.connect()
  # ...
end
```

Once the Statix connection is open, its `increment/1,2`, `decrement/1,2`, `gauge/2`, `set/2`, `timing/2`, and `measure/2` functions can be used to push metrics to the StatsD-compatible server.

`event/2,3` and `service_check/2,3` are DataDog StatsD protocol extensions not supported by standard StatsD servers.

### Sampling

Sampling is supported via the `:sample_rate` option:

```elixir
MyApp.Statix.increment("page_view", 1, sample_rate: 0.5)
```

The UDP packet will only be sent to the server about half of the time,
but the resulting value will be adjusted on the server according to the given sample rate.

NOTE: sampling is applied to all functions except `event/2,3` and `service_check/2,3`.

### Tags

Tags are a way of adding dimensions to metrics:

```elixir
MyApp.Statix.gauge("memory", 1, tags: ["region:east"])
```

### Configuration

Statix can be configured globally with:

```elixir
config :statix,
  prefix: "sample",
  host: "stats.tld",
  port: 8181
```

and on a per connection basis as well:

```elixir
config :statix, MyApp.Statix,
  port: 8811
```

The defaults are:

* prefix: `nil`
* host: `"127.0.0.1"`
* port: `8125`

__Note:__ by default, configuration is evaluated once, at compile time.
If you plan using other configuration at runtime, you must specify the `:runtime_config` option:

```elixir
defmodule MyApp.Statix do
  use Statix, runtime_config: true
end
```

## License

This software is licensed under [the ISC license](LICENSE).
