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
  Opens the connection to the StatsD-compatible server.

  The configuration is read from the configuration for the `:statix` application
  (both globally and per connection).
  """
  @callback connect() :: :ok

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
    current_conn =
      if Keyword.get(opts, :runtime_config, false) do
        quote do
          @statix_header_key Module.concat(__MODULE__, :__statix_header__)

          def connect() do
            conn = Statix.new_conn(__MODULE__)
            Application.put_env(:statix, @statix_header_key, conn.header)

            Statix.open_conn(conn)
            :ok
          end

          @compile {:inline, [current_conn: 0]}
          defp current_conn() do
            header = Application.fetch_env!(:statix, @statix_header_key)
            %Statix.Conn{header: header, sock: __MODULE__}
          end
        end
      else
        quote do
          @statix_conn Statix.new_conn(__MODULE__)

          def connect() do
            conn = @statix_conn
            current_conn = Statix.new_conn(__MODULE__)

            if conn.header != current_conn.header do
              raise(
                "the current configuration for #{inspect(__MODULE__)} differs from " <>
                  "the one that was given during the compilation.\n" <>
                  "Be sure to use :runtime_config option " <>
                  "if you want to have different configurations"
              )
            end

            Statix.open_conn(conn)
            :ok
          end

          @compile {:inline, [current_conn: 0]}
          defp current_conn() do
            @statix_conn
          end
        end
      end

    quote location: :keep do
      @behaviour Statix

      unquote(current_conn)

      def increment(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_conn(), :counter, key, val, options)
      end

      def decrement(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_conn(), :counter, key, [?-, to_string(val)], options)
      end

      def gauge(key, val, options \\ []) do
        Statix.transmit(current_conn(), :gauge, key, val, options)
      end

      def histogram(key, val, options \\ []) do
        Statix.transmit(current_conn(), :histogram, key, val, options)
      end

      def timing(key, val, options \\ []) do
        Statix.transmit(current_conn(), :timing, key, val, options)
      end

      def measure(key, options \\ [], fun) when is_function(fun, 0) do
        {elapsed, result} = :timer.tc(fun)

        timing(key, div(elapsed, 1000), options)

        result
      end

      def set(key, val, options \\ []) do
        Statix.transmit(current_conn(), :set, key, val, options)
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

  @doc false
  def new_conn(module) do
    {conn, prefix} =
      case load_config(module) do
        {:inet, {host, port, prefix}} ->
          conn = Conn.new(host, port)
          {conn, prefix}

        {:local, {socket_path, prefix}} ->
          {Conn.new(:local, socket_path), prefix}
      end

    header = IO.iodata_to_binary([conn.header | prefix])

    %{conn | header: header, sock: module}
  end

  @doc false
  def open_conn(%Conn{sock: module} = conn) do
    conn = Conn.open(conn)
    Process.register(conn.sock, module)
  end

  @doc false
  def transmit(conn, type, key, val, options)
      when (is_binary(key) or is_list(key)) and is_list(options) do
    sample_rate = Keyword.get(options, :sample_rate)

    if is_nil(sample_rate) or sample_rate >= :rand.uniform() do
      Conn.transmit(conn, type, key, to_string(val), put_global_tags(conn.sock, options))
    else
      :ok
    end
  end

  defp load_config(module) do
    {env2, env1} =
      Application.get_all_env(:statix)
      |> Keyword.pop(module, [])

    {prefix1, env1} = Keyword.pop_first(env1, :prefix)
    {prefix2, env2} = Keyword.pop_first(env2, :prefix)
    prefix = build_prefix(prefix1, prefix2)
    env = Keyword.merge(env1, env2)

    if env[:local] do
      {:local, {env[:socket_path], prefix}}
    else
      host = Keyword.get(env, :host, "127.0.0.1")
      port = Keyword.get(env, :port, 8125)
      {:inet, {host, port, prefix}}
    end
  end

  defp build_prefix(part1, part2) do
    case {part1, part2} do
      {nil, nil} -> ""
      {_p1, nil} -> [part1, ?.]
      {nil, _p2} -> [part2, ?.]
      {_p1, _p2} -> [part1, ?., part2, ?.]
    end
  end

  defp put_global_tags(module, options) do
    conn_tags =
      :statix
      |> Application.get_env(module, [])
      |> Keyword.get(:tags, [])

    app_tags = Application.get_env(:statix, :tags, [])
    global_tags = conn_tags ++ app_tags

    Keyword.update(options, :tags, global_tags, &(&1 ++ global_tags))
  end
end
