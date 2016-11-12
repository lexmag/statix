defmodule Statix do
  alias __MODULE__.Conn

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
            Statix.open_conn(@statix_conn)
            :ok
          end

          @compile {:inline, [current_conn: 0]}
          defp current_conn() do
            @statix_conn
          end
        end
      end

    quote location: :keep do
      unquote(current_conn)

      def increment(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_conn(), :counter, key, val, options)
      end

      def decrement(key, val \\ 1, options \\ []) when is_number(val) do
        Statix.transmit(current_conn(), :counter, key, [?-, to_string(val)], options)
      end

      def gauge(key, val, options \\ [] ) do
        Statix.transmit(current_conn(), :gauge, key, val, options)
      end

      def histogram(key, val, options \\ []) do
        Statix.transmit(current_conn(), :histogram, key, val, options)
      end

      def timing(key, val, options \\ []) do
        Statix.transmit(current_conn(), :timing, key, val, options)
      end

      @doc """
      Measure a function call.

      It returns the result of the function call, making it suitable
      for pipelining and easily wrapping existing code.
      """
      def measure(key, options \\ [], fun) when is_function(fun, 0) do
        {elapsed, result} = :timer.tc(fun)

        timing(key, div(elapsed, 1000), options)

        result
      end

      def set(key, val, options \\ []) do
        Statix.transmit(current_conn(), :set, key, val, options)
      end
    end
  end

  def new_conn(module) do
    {host, port, prefix} = load_config(module)
    conn = Conn.new(host, port)
    header = IO.iodata_to_binary([conn.header | prefix])
    %{conn | header: header, sock: module}
  end

  def open_conn(%Conn{sock: module} = conn) do
    conn = Conn.open(conn)
    Process.register(conn.sock, module)
  end

  def transmit(conn, type, key, val, options \\ [])
      when (is_binary(key) or is_list(key)) and is_list(options) do
    if Keyword.get(options, :sample_rate, 1.0) >= :rand.uniform() do
      Conn.transmit(conn, type, key, to_string(val), options)
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
    env = Keyword.merge(env1, env2)

    host = Keyword.get(env, :host, "127.0.0.1")
    port = Keyword.get(env, :port, 8125)
    prefix = build_prefix(prefix1, prefix2)
    {host, port, prefix}
  end

  defp build_prefix(part1, part2) do
    case {part1, part2} do
      {nil, nil} -> ""
      {_p1, nil} -> [part1, ?.]
      {nil, _p2} -> [part2, ?.]
      {_p1, _p2} -> [part1, ?., part2, ?.]
    end
  end
end
