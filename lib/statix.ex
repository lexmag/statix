defmodule Statix do
  defmacro __using__(_opts) do
    quote location: :keep do
      {host, port, prefix} = Statix.config(__MODULE__)
      conn = Statix.Conn.new(host, port)
      header = [conn.header | prefix]
      @statix_conn %{conn | header: header, sock: __MODULE__}

      def connect() do
        conn = Statix.Conn.open(@statix_conn)
        Process.register(conn.sock, __MODULE__)
        :ok
      end

      def increment(key, val \\ "1") do
        @statix_conn
        |> Statix.transmit(:counter, key, val)
      end

      def decrement(key, val \\ "1") do
        @statix_conn
        |> Statix.transmit(:counter, key, [?-, to_string(val)])
      end

      def gauge(key, val) do
        @statix_conn
        |> Statix.transmit(:gauge, key, val)
      end

      def histogram(key, val) do
        @statix_conn
        |> Statix.transmit(:histogram, key, val)
      end

      def timing(key, val) do
        @statix_conn
        |> Statix.transmit(:timing, key, val)
      end

      @doc """
      Measure a function call.

      It returns the result of the function call, making it suitable
      for pipelining and easily wrapping existing code.
      """
      def measure(key, fun) when is_function(fun, 0) do
        {time, result} = :timer.tc(fun)

        timing(key, div(time, 1000))

        result
      end

      def set(key, val) do
        @statix_conn
        |> Statix.transmit(:set, key, val)
      end
    end
  end

  def transmit(conn, type, key, val) when is_binary(key) or is_list(key) do
    Statix.Conn.transmit(conn, type, key, to_string(val))
  end

  def config(module) do
    {prefix1, prefix2, env} = get_params(module)
    {Keyword.get(env, :host, "127.0.0.1"),
     Keyword.get(env, :port, 8125),
     build_prefix(prefix1, prefix2)}
  end

  defp get_params(module) do
    {env2, env1} = pull_env(module)
    {prefix1, env1} = Keyword.pop_first(env1, :prefix)
    {prefix2, env2} = Keyword.pop_first(env2, :prefix)
    {prefix1, prefix2, Keyword.merge(env1, env2)}
  end

  defp pull_env(module) do
    Application.get_all_env(:statix)
    |> Keyword.pop(module, [])
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
