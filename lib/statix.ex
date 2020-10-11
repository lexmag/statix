defmodule Statix do
  @moduledoc """
  Writer for [StatsD](https://github.com/etsy/statsd)-compatible servers.

  To get started with Statix, you have to create a module that calls `use
  Statix`, like this:

      defmodule MyApp.Statix do
        use Statix
      end

  This will make `MyApp.Statix` a Statix connection that implements the `Statix`
  behaviour. This connection can be started with the `MyApp.Statix.connect/1`
  function (see the `c:connect/1` callback) and a few functions can be called on
  it to report metrics to the StatsD-compatible server read from the
  configuration. Usually, `connect/1` is called in your application's
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
      See the "Tags" section for more information.
    * `:pool_size` - (integer) number of ports used to distribute the metric sending.
      Defaults to `1`. See the "Pooling" section for more information.

  By default, the configuration is evaluated once, at compile time.
  If you plan on changing the configuration at runtime, you must specify the
  `:runtime_config` option to be `true` when calling `use Statix`:

      defmodule MyApp.Statix do
        use Statix, runtime_config: true
      end

  ## Tags

  Tags are a way of adding dimensions to metrics:

      MyApp.Statix.gauge("memory", 1, tags: ["region:east"])

  In the example above, the `memory` measurement has been tagged with
  `region:east`. Not all StatsD-compatible servers support this feature.

  Tags could also be added globally to be included in every metric sent:

      config :statix, tags: ["env:\#{Mix.env()}"]


  ## Sampling

  All the callbacks from the `Statix` behaviour that accept options support
  sampling via the `:sample_rate` option (see also the `t:options/0` type).

      MyApp.Statix.increment("page_view", 1, sample_rate: 0.5)

  In the example above, the UDP packet will only be sent to the server about
  half of the time, but the resulting value will be adjusted on the server
  according to the given sample rate.

  ## Pooling

  Statix transmits data using [ports](https://hexdocs.pm/elixir/Port.html).

  If a port is busy when you try to send a command to it, the sender may be suspended and some blocking may occur. This becomes more of an issue in highly concurrent environments.

  In order to get around that, Statix allows you to start multiple ports, and randomly picks one at the time of transmit.

  This option can be configured via the `:pool_size` option:

      config :statix, MyApp.Statix,
        pool_size: 3

  """

  alias __MODULE__.Conn

  @type key :: iodata
  @type options :: [sample_rate: float, tags: [String.t()]]
  @type on_send :: :ok | {:error, term}

  @type event_options :: [
          timestamp: integer,
          hostname: String.t(),
          aggregation_key: String.t(),
          priority: :low | :normal,
          source_type_name: String.t(),
          alert_type: :error | :warning | :info | :success,
          tags: [String.t()]
        ]

  @doc """
  Same as `connect([])`.
  """
  @callback connect() :: :ok

  @doc """
  Opens the connection to the StatsD-compatible server.

  The configuration is read from the environment for the `:statix` application
  (both globally and per connection).

  The given `options` override the configuration read from the application environment.
  """
  @callback connect(options :: keyword) :: :ok

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
  Same as `timing(key, value, [])`.
  """
  @callback timing(key, value :: String.Chars.t()) :: on_send

  @doc """
  Writes the given `value` to the StatsD timing identified by `key`.

  `value` is expected in milliseconds.

  ## Examples

      iex> MyApp.Statix.timing("rendering", 12, [])
      :ok

  """
  @callback timing(key, value :: String.Chars.t(), options) :: on_send

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

  @doc """
  Emits event to the event stream (note: this is a DataDog StatsD protocol extension).
  """
  @callback event(title :: String.t(), text :: String.t(), event_options) :: on_send

  defmacro __using__(opts) do
    current_statix =
      if Keyword.get(opts, :runtime_config, false) do
        quote do
          @statix_key Module.concat(__MODULE__, :__statix__)

          def connect(options \\ []) do
            statix = Statix.new(__MODULE__, options)
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

          def connect(options \\ []) do
            if @statix != Statix.new(__MODULE__, options) do
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

      def event(title, text, options \\ []) do
        Statix.transmit(current_statix(), :event, title, text, options)
      end

      defoverridable(
        increment: 3,
        decrement: 3,
        gauge: 3,
        histogram: 3,
        timing: 3,
        measure: 3,
        set: 3,
        event: 3
      )
    end
  end

  defstruct [:conn, :tags, :pool]

  @doc false
  def new(module, options) do
    config = get_config(module, options)
    conn = Conn.new(config.host, config.port)
    header = IO.iodata_to_binary([conn.header | config.prefix])

    %__MODULE__{
      conn: %{conn | header: header},
      pool: build_pool(module, config.pool_size),
      tags: config.tags
    }
  end

  defp build_pool(module, 1), do: [module]

  defp build_pool(module, size) do
    Enum.map(1..size, &:"#{module}-#{&1}")
  end

  @doc false
  def open(%__MODULE__{conn: conn, pool: pool}) do
    Enum.each(pool, fn name ->
      %{sock: sock} = Conn.open(conn)
      Process.register(sock, name)
    end)
  end

  @doc false
  def transmit(
        %{conn: conn, pool: pool, tags: tags},
        type,
        key,
        value,
        options
      )
      when (is_binary(key) or is_list(key)) and is_list(options) do
    sample_rate = Keyword.get(options, :sample_rate)

    if is_nil(sample_rate) or sample_rate >= :rand.uniform() do
      options = put_global_tags(options, tags)

      %{conn | sock: pick_name(pool)}
      |> Conn.transmit(type, key, to_string(value), options)
    else
      :ok
    end
  end

  defp pick_name([name]), do: name
  defp pick_name(pool), do: Enum.random(pool)

  defp get_config(module, overrides) do
    {module_env, global_env} =
      :statix
      |> Application.get_all_env()
      |> Keyword.pop(module, [])

    env = module_env ++ global_env
    options = overrides ++ env

    tags =
      Keyword.get_lazy(overrides, :tags, fn ->
        env |> Keyword.get_values(:tags) |> Enum.concat()
      end)

    %{
      prefix: build_prefix(env, overrides),
      host: Keyword.get(options, :host, "127.0.0.1"),
      port: Keyword.get(options, :port, 8125),
      pool_size: Keyword.get(options, :pool_size, 1),
      tags: tags
    }
  end

  defp build_prefix(env, overrides) do
    case Keyword.fetch(overrides, :prefix) do
      {:ok, prefix} ->
        [prefix, ?.]

      :error ->
        env
        |> Keyword.get_values(:prefix)
        |> Enum.map_join(&(&1 && [&1, ?.]))
    end
  end

  defp put_global_tags(options, []), do: options

  defp put_global_tags(options, tags) do
    Keyword.update(options, :tags, tags, &(&1 ++ tags))
  end
end
