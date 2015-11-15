# Statix [![Build Status](https://travis-ci.org/lexmag/statix.svg)](https://travis-ci.org/lexmag/statix)

Statix is an Elixir client for StatsD compatible servers.
It is focusing on wicked-fast _speed_ without sacrificing _simplicity_, _completeness_, or _correctness_.

What makes Statix to be the fastest library:

  * direct sending to the socket <sup>[[1](#direct-sending)]</sup>
  * caching of the UDP packets header
  * [IO list](http://jlouisramblings.blogspot.se/2013/07/problematic-traits-in-erlang.html) utilization

<sup><a name="direct-sending"></a>[1]</sup> In contrast with process-based clients it has much lower memory consumption and incredibly high throughput:

* Statix (v0.0.1): ~__554734__ counter increments per flush

![Statix](https://www.dropbox.com/s/9618kb09sc6cyh3/statix-v0.0.1.png?raw=1)

* statsderl (v0.3.5): ~__21715__ counter increments per flush

![statsderl](https://www.dropbox.com/s/wt96xmuywka9m4k/statsderl-v0.3.5.png?raw=1)

## Installation

Add Statix as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:statix]]
end

defp deps() do
  [{:statix, "~> 0.5"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

A module that uses Statix represents a socket connection:

```elixir
defmodule Sample.Statix do
  use Statix
end
```

Before using connection the `connect/0` function needs to be invoked.
In general, this function is called during the invocation of your application `start/2` callback.

```elixir
def start(_type, _args) do
  :ok = Sample.Statix.connect
  # ...
end
```

Thereafter, the `increment/1,2`, `decrement/1,2`, `gauge/2`, `set/2`, `timing/2` and `measure/2` functions will be successfully pushing metrics to the server.

### Configuration

Statix could be configured globally with:

```elixir
config :statix,
  prefix: "sample",
  host: "127.0.0.1", port: 8181
```

and on a per connection basis as well:

```elixir
config :statix, Sample.Statix,
  port: 8811
```

## License

This software is licensed under [the ISC license](LICENSE).
