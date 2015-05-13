defmodule Statix do
  defmacro __using__(_opts) do
    quote location: :keep do
      alias Statix.Conn

      {addr, port, prefix} = Statix.config(__MODULE__)
      {:ok, header} = Conn.build_header(addr, port)
      @statix_conn %Conn{header: [header, prefix], sock: __MODULE__}

      def connect() do
        {:ok, sock} = Conn.open_sock()
        Process.register(sock, __MODULE__)
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

      def timing(key, val) do
        @statix_conn
        |> Statix.transmit(:timing, key, val)
      end
    end
  end

  def transmit(conn, type, key, val) do
    Statix.Conn.transmit(conn, type, key, to_string(val))
  end

  def config(module) do
    {prefix1, prefix2, env} = get_params(module)
    {Keyword.get(env, :address, {127, 0, 0, 1}),
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
