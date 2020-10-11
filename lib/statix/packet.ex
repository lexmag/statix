defmodule Statix.Packet do
  @moduledoc false

  use Bitwise

  otp_release = :erlang.system_info(:otp_release)
  @addr_family if(otp_release >= '19', do: [1], else: [])

  def header({n1, n2, n3, n4}, port) do
    true = Code.ensure_loaded?(:gen_udp)

    anc_data_part =
      if function_exported?(:gen_udp, :send, 5) do
        [0, 0, 0, 0]
      else
        []
      end

    @addr_family ++
      [
        band(bsr(port, 8), 0xFF),
        band(port, 0xFF),
        band(n1, 0xFF),
        band(n2, 0xFF),
        band(n3, 0xFF),
        band(n4, 0xFF)
      ] ++ anc_data_part
  end

  def build(header, :event, key, val, options) do
    title_len = key |> String.length() |> Integer.to_string()
    text_len = val |> String.length() |> Integer.to_string()

    [header, "_e{", title_len, ",", text_len, "}:", key, "|", val]
    |> set_ext_option("d", options[:timestamp])
    |> set_ext_option("h", options[:hostname])
    |> set_ext_option("k", options[:aggregation_key])
    |> set_ext_option("p", options[:priority])
    |> set_ext_option("s", options[:source_type_name])
    |> set_ext_option("t", options[:alert_type])
    |> set_option(:sample_rate, options[:sample_rate])
    |> set_option(:tags, options[:tags])
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

  defp set_ext_option(packet, _opt_key, nil) do
    packet
  end

  defp set_ext_option(packet, opt_key, value) do
    [packet | [?|, opt_key, ?:, to_string(value)]]
  end
end
