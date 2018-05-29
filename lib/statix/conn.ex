defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :header]

  alias Statix.Packet
  require Logger

  def new(host, port) when is_binary(host) do
    new(string_to_charlist(host), port)
  end

  def new(host, port) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    header = Packet.header(addr, port)
    %__MODULE__{header: header}
  end

  def open(%__MODULE__{} = conn) do
    {:ok, sock} = :gen_udp.open(0, [active: false])
    %__MODULE__{conn | sock: sock}
  end

  def transmit(%__MODULE__{} = conn, type, key, val, options)
      when is_binary(val) and is_list(options) do
    packet = Packet.build(conn.header, type, key, val, options)
    case transmit(packet, conn.sock) do
      :ok ->
        :ok
      {:error, :port_closed} = err ->
        Logger.error(fn ->
          "#{inspect __MODULE__} #{type} metric \"#{key}\" lost value #{val}" <>
          " due to port closure"
        end)
        err
    end
  end

  defp transmit(packet, sock) do
    try do
      Port.command(sock, packet)
      receive do
        {:inet_reply, _port, status} -> status
      end
    rescue
      ArgumentError ->
        {:error, :port_closed}
    end
  end
  
  if Version.match?(System.version(), ">= 1.3.0") do
    defp string_to_charlist(string), do: String.to_charlist(string)
  else
    defp string_to_charlist(string), do: String.to_char_list(string)
  end
end
