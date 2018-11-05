defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :header, :type]

  alias Statix.Packet

  def new(:local, path) do
    header = Packet.header(:local, path)
    %__MODULE__{header: header, type: :local}
  end

  def new(host, port) when is_binary(host) do
    new(string_to_charlist(host), port)
  end

  def new(host, port) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    header = Packet.header(:inet, addr, port)
    %__MODULE__{header: header, type: :inet}
  end

  def open(%__MODULE__{type: :inet} = conn) do
    {:ok, sock} = :gen_udp.open(0, active: false)
    %__MODULE__{conn | sock: sock}
  end

  def open(%__MODULE__{type: :local} = conn) do
    {:ok, sock} = :gen_udp.open(0, [:local, active: false])
    %__MODULE__{conn | sock: sock}
  end

  def transmit(%__MODULE__{} = conn, type, key, val, options)
      when is_binary(val) and is_list(options) do
    Packet.build(conn.header, type, key, val, options)
    |> transmit(conn.sock)
  end

  defp transmit(packet, sock) do
    Port.command(sock, packet)

    receive do
      {:inet_reply, _port, status} -> status
    end
  end

  if Version.match?(System.version(), ">= 1.3.0") do
    defp string_to_charlist(string), do: String.to_charlist(string)
  else
    defp string_to_charlist(string), do: String.to_char_list(string)
  end
end
