defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :address, :port, :prefix]

  alias Statix.Packet

  require Logger

  otp_release = :erlang.system_info(:otp_release)
  @otp_gte_26 otp_release >= ~c"26"

  def new(host, port, prefix) when is_binary(host) do
    new(String.to_charlist(host), port, prefix)
  end

  def new(host, port, prefix) when is_list(host) or is_tuple(host) do
    case :inet.getaddr(host, :inet) do
      {:ok, address} ->
        %__MODULE__{address: address, port: port, prefix: prefix}

      {:error, reason} ->
        raise(
          "cannot get the IP address for the provided host " <>
            "due to reason: #{:inet.format_error(reason)}"
        )
    end
  end

  def open(%__MODULE__{} = conn) do
    {:ok, sock} = :gen_udp.open(0, active: false)
    %__MODULE__{conn | sock: sock}
  end

  def transmit(%__MODULE__{sock: sock, prefix: prefix} = conn, type, key, val, options)
      when is_binary(val) and is_list(options) do
    result =
      prefix
      |> Packet.build(type, key, val, options)
      |> transmit(conn)

    with {:error, error} <- result do
      Logger.error(fn ->
        if(is_atom(sock), do: "", else: "Statix ") <>
          "#{inspect(sock)} #{type} metric \"#{key}\" lost value #{val}" <>
          " error=#{inspect(error)}"
      end)
    end

    result
  end

  defp transmit(packet, %__MODULE__{address: address, port: port, sock: sock_name}) do
    sock = Process.whereis(sock_name)

    # The check below was implemented for backwards compatibility to avoid a performance issue on
    # OTP on versiones older than 26. If the OTP version is 26 or above, we use gen_udp.send/4. If
    # the version is older than that, we use the existing performance issue workaround.
    if @otp_gte_26 do
      if sock do
        :gen_udp.send(sock, address, port, packet)
      else
        {:error, :port_closed}
      end
    else
      # This branch will only be executed on older version of OTP and will be eventually removed.
      packet_with_header = Packet.add_header(packet, address, port)

      try do
        Port.command(sock, packet_with_header)
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
  end
end
