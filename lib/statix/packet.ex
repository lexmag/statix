defmodule Statix.Packet do
  @moduledoc false

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
