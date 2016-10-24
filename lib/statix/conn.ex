defmodule Statix.Conn do
  defstruct [:sock, :header]

  alias Statix.Packet

  def new(host, port) when is_binary(host) do
    new(String.to_char_list(host), port)
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

  def transmit(%__MODULE__{} = conn, type, key, val, options) when is_binary(val) do
    Packet.build(conn.header, type, key, val, options)
    |> transmit(conn.sock)
  end

  defp transmit(packet, sock) do
    Port.command(sock, packet)
    receive do
      {:inet_reply, _port, status} -> status
    end
  end
end
