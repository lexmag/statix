defmodule Statix.Packet do
  @moduledoc false

  import Bitwise

  @doc """
  Adds header to a built packet.
  This is implemented to keep backwards compatibility with older OTP versions
  (< 26). Will be eventually removed.
  """
  def add_header(built_packet, {n1, n2, n3, n4}, port) do
    true = Code.ensure_loaded?(:gen_udp)

    anc_data_part =
      if function_exported?(:gen_udp, :send, 5) do
        [0, 0, 0, 0]
      else
        []
      end

    header =
      [
        _addr_family = 1,
        band(bsr(port, 8), 0xFF),
        band(port, 0xFF),
        band(n1, 0xFF),
        band(n2, 0xFF),
        band(n3, 0xFF),
        band(n4, 0xFF)
      ] ++ anc_data_part

    header_as_bytes = Enum.into(header, <<>>, fn byte -> <<byte>> end)
    [header_as_bytes | built_packet]
  end

  def build(prefix, name, key, val, options) do
    [prefix, key, ?:, val, ?|, metric_type(name)]
    |> set_option(:sample_rate, options[:sample_rate])
    |> set_option(:tags, options[:tags])
  end

  metrics = %{
    counter: "c",
    gauge: "g",
    histogram: "h",
    timing: "ms",
    set: "s"
  }

  for {name, type} <- metrics do
    defp metric_type(unquote(name)), do: unquote(type)
  end

  defp set_option(packet, _kind, nil) do
    packet
  end

  defp set_option(packet, :sample_rate, sample_rate) when is_float(sample_rate) do
    [packet | ["|@", :erlang.float_to_binary(sample_rate, [:compact, decimals: 2])]]
  end

  defp set_option(packet, :tags, []), do: packet

  defp set_option(packet, :tags, tags) when is_list(tags) do
    [packet | ["|#", Enum.join(tags, ",")]]
  end
end
