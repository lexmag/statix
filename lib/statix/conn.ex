defmodule Statix.Conn do
  defstruct [:sock, :header]

  alias Statix.Packet

  def open(addr, port) do
    {:ok, header} = build_header(addr, port)
    {:ok, sock} = open_sock()
    %__MODULE__{sock: sock, header: header}
  end

  def build_header(addr, port) do
    {:ok, Packet.header(addr, port)}
  end

  def open_sock() do
    :gen_udp.open(0, [active: false])
  end

  def transmit(%__MODULE__{} = conn, type, key, val)
      when is_binary(key) and is_binary(val) do
    Packet.build(conn.header, type, key, val)
    |> transmit(conn.sock)
  end

  defp transmit(packet, sock) do
    Port.command(sock, packet)
    receive do
      {:inet_reply, _sock, status} -> status
    end
  end
end
