defmodule Statix do
  @moduledoc """
  Writer for [StatsD](https://github.com/etsy/statsd)-compatible servers.

  To get started with Statix, you have to create a module that calls `use
  Statix`, like this:

      defmodule MyApp.Statix do
        use Statix
      end

  This will make `MyApp.Statix` a Statix connection that implements the `Statix`
  behaviour. This connection can be started with the `MyApp.Statix.connect/0`
  function (see the `c:connect/0` callback) and a few functions can be called on
  it to report metrics to the StatsD-compatible server read from the
  configuration. Usually, `connect/0` is called in your application's
  `c:Application.start/2` callback:

      def start(_type, _args) do
        :ok = MyApp.Statix.connect()

        # ...
      end

  ## Configuration

  Statix can be configured either globally or on a per-connection basis.

  The global configuration will affect all Statix connections created with
  `use Statix`; it can be specified by configuring the `:statix` application:

      config :statix,
        prefix: "sample",
        host: "stats.tld",
        port: 8181

  The per-connection configuration can be specified by configuring each specific
  connection module under the `:statix` application:

      config :statix, MyApp.Statix,
        port: 8123

  The following is a list of all the supported options:

    * `:prefix` - (binary) all metrics sent to the StatsD-compatible
      server through the configured Statix connection will be prefixed with the
      value of this option. By default this option is not present.
    * `:host` - (binary) the host where the StatsD-compatible server is running.
      Defaults to `"127.0.0.1"`.
    * `:port` - (integer) the port (on `:host`) where the StatsD-compatible
      server is running. Defaults to `8125`.
    * `:tags` - ([binary]) a list of global tags that will be sent with all
      metrics. By default this option is not present.

  By default, the configuration is evaluated once, at compile time. If you plan
  on changing the configuration at runtime, you must specify the
  `:runtime_config` option to be `true` when calling `use Statix`:

      defmodule MyApp.Statix do
        use Statix, runtime_config: true
      end

  ## Tags

  Tags are a way of adding dimensions to metrics:

      MyApp.Statix.gauge("memory", 1, tags: ["region:east"])

  In the example above, the `memory` measurement has been tagged with
  `region:east`. Not all StatsD-compatible servers support this feature.

  ## Sampling

  All the callbacks from the `Statix` behaviour that accept options support
  sampling via the `:sample_rate` option (see also the `t:options/0` type).

      MyApp.Statix.increment("page_view", 1, sample_rate: 0.5)

  In the example above, the UDP packet will only be sent to the server about
  half of the time, but the resulting value will be adjusted on the server
  according to the given sample rate.
  """

  alias __MODULE__.Conn

  @type key :: iodata
  @type options :: [sample_rate: float, tags: [String.t()]]
  @type on_send :: :ok | {:error, term}

  @doc """
  Same as `connect([])`.
  """
  @callback connect() :: :ok

  @doc """
  Opens the connection to the StatsD-compatible server.

  The configuration is read from the configuration for the `:statix` application
  (both globally and per connection).

  The given `config` overrides the configuration read from the application environment.
  """
  @callback connect(config :: keyword) :: :ok

  @doc """
  Increments the StatsD counter identified by `key` by the given `value`.

  `value` is supposed to be zero or positive and `c:decrement/3` should be
  used for negative values.

  ## Examples

      iex> MyApp.Statix.increment("hits", 1, [])
      :ok

  """
  @callback increment(key, value :: number, options) :: on_send

  @doc """
  Same as `increment(key, 1, [])`.
  """
  @callback increment(key) :: on_send

  @doc """
  Same as `increment(key, value, [])`.
  """
  @callback increment(key, value :: number) :: on_send

  @doc """
  Decrements the StatsD counter identified by `key` by the given `value`.

  Works same as `c:increment/3` but subtracts `value` instead of adding it. For
  this reason `value` should be zero or negative.

  ## Examples

      iex> MyApp.Statix.decrement("open_connections", 1, [])
      :ok

  """
  @callback decrement(key, value :: number, options) :: on_send

  @doc """
  Same as `decrement(key, 1, [])`.
  """
  @callback decrement(key) :: on_send

  @doc """
  Same as `decrement(key, value, [])`.
  """
  @callback decrement(key, value :: number) :: on_send

  @doc """
  Writes to the StatsD gauge identified by `key`.

  ## Examples

      iex> MyApp.Statix.gauge("cpu_usage", 0.83, [])
      :ok

  """
  @callback gauge(key, value :: String.Chars.t(), options) :: on_send

  @doc """
  Same as `gauge(key, value, [])`.
  """
  @callback gauge(key, value :: String.Chars.t()) :: on_send

  @doc """
  Writes `value` to the histogram identified by `key`.

  Not all StatsD-compatible servers support histograms. An example of a such
  server [statsite](https://github.com/statsite/statsite).

  ## Examples

      iex> MyApp.Statix.histogram("online_users", 123, [])
      :ok

  """
  @callback histogram(key, value :: String.Chars.t(), options) :: on_send

  @doc """
  Same as `histogram(key, value, [])`.
  """
  @callback histogram(key, value :: String.Chars.t()) :: on_send

  @doc """
  Writes the given `value` to the StatsD timing identified by `key`.

  `value` is expected in milliseconds.

  ## Examples

      iex> MyApp.Statix.timing("rendering", 12, [])
      :ok

  """
  @callback timing(key, value :: String.Chars.t(), options) :: on_send

  @doc """
  Same as `timing(key, value, [])`.
  """
  @callback timing(key, value :: String.Chars.t()) :: on_send

  @doc """
  Writes the given `value` to the StatsD set identified by `key`.

  ## Examples

      iex> MyApp.Statix.set("unique_visitors", "user1", [])
      :ok

  """
  @callback set(key, value :: String.Chars.t(), options) :: on_send

  @doc """
  Same as `set(key, value, [])`.
  """
  @callback set(key, value :: String.Chars.t()) :: on_send

  @doc """
  Measures the execution time of the given `function` and writes that to the
  StatsD timing identified by `key`.

  This function returns the value returned by `function`, making it suitable for
  easily wrapping existing code.

  ## Examples

      iex> MyApp.Statix.measure("integer_to_string", [], fn -> Integer.to_string(123) end)
      "123"

  """
  @callback measure(key, options, function :: (() -> result)) :: result when result: var

  @doc """
  Same as `measure(key, [], function)`.
  """
  @callback measure(key, function :: (() -> result)) :: result when result: var

  defmacro __using__(opts) do
    current_statix =
      if Keyword.get(opts, :runtime_config, false) do
        quote do
          @statix_key Module.concat(__MODULE__, :__statix__)

          def connect(config \\ []) do
            statix = Statix.new(__MODULE__, config)
            Application.put_env(:statix, @statix_key, statix)

            Statix.open(statix)
            :ok
          end

          @compile {:inline, [current_statix: 0]}

          defp current_statix() do
            Application.fetch_env!(:statix, @statix_key)
          end
        end
      else
        quote do
          @statix Statix.new(__MODULE__, [])

          def connect(config \\ []) do
            if @statix != Statix.new(__MODULE__, config) do
              raise(
                "the current configuration for #{inspect(__MODULE__)} differs from " <>
                  "the one that was given during the compilation.\n" <>
                  "Be sure to use :runtime_config option " <>
                  "if you want to have different configurations"
              )
            end

            Statix.open(@statix)
            :ok
          end

          @compile {:inline, [current_statix: 0]}

          defp current_statix(), do: @statix
        end
      end

    quote location: :keep do
      @behaviour Statix

      unquote(current_statix)

      def increment(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_statix(), :counter, key, val, options)
      end

      def decrement(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_statix(), :counter, key, [?-, to_string(val)], options)
      end

      def gauge(key, val, options \\ []) do
        Statix.transmit(current_statix(), :gauge, key, val, options)
      end

      def histogram(key, val, options \\ []) do
        Statix.transmit(current_statix(), :histogram, key, val, options)
      end

      def timing(key, val, options \\ []) do
        Statix.transmit(current_statix(), :timing, key, val, options)
      end

      def measure(key, options \\ [], fun) when is_function(fun, 0) do
        {elapsed, result} = :timer.tc(fun)

        timing(key, div(elapsed, 1000), options)

        result
      end

      def set(key, val, options \\ []) do
        Statix.transmit(current_statix(), :set, key, val, options)
      end

      defoverridable(
        increment: 3,
        decrement: 3,
        gauge: 3,
        histogram: 3,
        timing: 3,
        measure: 3,
        set: 3
      )
    end
  end

  defstruct [:conn, :tags]

  @doc false
  def new(module, config) do
    config =
      module
      |> get_config()
      |> Map.merge(Map.new(config))

    conn = Conn.new(config.host, config.port)
    header = IO.iodata_to_binary([conn.header | config.prefix])

    %__MODULE__{
      conn: %{conn | header: header, sock: module},
      tags: config.tags
    }
  end

  @doc false
  def open(%__MODULE__{conn: %{sock: module} = conn}) do
    %{sock: sock} = Conn.open(conn)
    Process.register(sock, module)
  end

  @doc false
  def transmit(%{conn: conn, tags: tags}, type, key, value, options)
      when (is_binary(key) or is_list(key)) and is_list(options) do
    sample_rate = Keyword.get(options, :sample_rate)

    if is_nil(sample_rate) or sample_rate >= :rand.uniform() do
      options = put_global_tags(options, tags)

      Conn.transmit(conn, type, key, to_string(value), options)
    else
      :ok
    end
  end

  defp get_config(module) do
    {conn_env, global_env} =
      :statix
      |> Application.get_all_env()
      |> Keyword.pop(module, [])

    {global_prefix, global_env} = Keyword.pop_first(global_env, :prefix)
    {conn_prefix, conn_env} = Keyword.pop_first(conn_env, :prefix)
    prefix = build_prefix(global_prefix, conn_prefix)

    {global_tags, global_env} = Keyword.pop_first(global_env, :tags, [])
    {conn_tags, conn_env} = Keyword.pop_first(conn_env, :tags, [])
    tags = global_tags ++ conn_tags

    env = Keyword.merge(global_env, conn_env)
    host = Keyword.get(env, :host, "127.0.0.1")
    port = Keyword.get(env, :port, 8125)

    %{
      prefix: prefix,
      host: host,
      port: port,
      tags: tags
    }
  end

  defp build_prefix(global_part, conn_part) do
    case {global_part, conn_part} do
      {nil, nil} -> ""
      {_, nil} -> [global_part, ?.]
      {nil, _} -> [conn_part, ?.]
      {_, _} -> [global_part, ?., conn_part, ?.]
    end
  end

  defp put_global_tags(options, []), do: options

  defp put_global_tags(options, tags) do
    Keyword.update(options, :tags, tags, &(&1 ++ tags))
  end
end
