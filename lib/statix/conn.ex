defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :header, :sample_rate]

  alias Statix.Packet

  def new(host, port, sample_rate) when is_binary(host) do
    new(string_to_charlist(host), port, sample_rate)
  end

  def new(host, port, sample_rate) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    header = Packet.header(addr, port)
    %__MODULE__{header: header, sample_rate: sample_rate}
  end

  def open(%__MODULE__{} = conn) do
    {:ok, sock} = :gen_udp.open(0, [active: false])
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
