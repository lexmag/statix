defmodule Statix.Conn do
  @moduledoc false

  defstruct [:socks, :sock_names, :header, :module, :pool_size]

  alias Statix.Packet

  require Logger

  def new(module, host, port, pool_size) when is_binary(host) do
    new(module, String.to_charlist(host), port, pool_size)
  end

  def new(module, host, port, pool_size) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    header = Packet.header(addr, port)
    names = sock_names(module, pool_size)
    %__MODULE__{header: header, sock_names: names, pool_size: pool_size}
  end

  def open(%__MODULE__{pool_size: pool_size} = conn) do
    socks =
      for _ <- 1..pool_size do
        {:ok, sock} = :gen_udp.open(0, active: false)
        sock
      end

    %__MODULE__{conn | socks: socks}
  end

  def transmit(
        %__MODULE__{header: header, sock_names: socks, module: module},
        type,
        key,
        val,
        options
      )
      when is_binary(val) and is_list(options) do
    result =
      header
      |> Packet.build(type, key, val, options)
      |> transmit(socks)

    if result == {:error, :port_closed} do
      Logger.error(fn ->
        if(is_atom(module), do: "", else: "Statix ") <>
          "#{inspect(module)} #{type} metric \"#{key}\" lost value #{val}" <>
          " due to port closure"
      end)
    end

    result
  end

  defp transmit(packet, socks) do
    try do
      socks
      |> choose_sock()
      |> Port.command(packet)
    rescue
      ArgumentError ->
        {:error, :port_closed}
    else
      true ->
        receive do
          {:inet_reply, _port, status} -> status
        end
    end
  end

  defp choose_sock([sock]), do: sock
  defp choose_sock(socks), do: Enum.random(socks)

  defp sock_names(module, pool_size) when pool_size > 1 do
    for i <- 1..pool_size do
      String.to_atom("#{module}#{i}")
    end
  end

  defp sock_names(module, _), do: [module]
end
