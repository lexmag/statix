defmodule Statix.Packet do
  @moduledoc false

  import Bitwise

  def header({n1, n2, n3, n4}, port) do
    true = Code.ensure_loaded?(:gen_udp)

    anc_data_part =
      if function_exported?(:gen_udp, :send, 5) do
        [0, 0, 0, 0]
      else
        []
      end

    [
      _addr_family = 1,
      band(bsr(port, 8), 0xFF),
      band(port, 0xFF),
      band(n1, 0xFF),
      band(n2, 0xFF),
      band(n3, 0xFF),
      band(n4, 0xFF)
    ] ++ anc_data_part
  end

  def build(header, name, key, val, options) do
    [header, key, ?:, val, ?|, metric_type(name)]
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
