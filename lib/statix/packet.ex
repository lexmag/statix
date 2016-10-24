defmodule Statix.Packet do
  use Bitwise

  otp_release = :erlang.system_info(:otp_release)
  @addr_family if(otp_release >= '19', do: [1], else: [])

  def header({n1, n2, n3, n4}, port) do
    @addr_family ++ [
      band(bsr(port, 8), 0xFF),
      band(port, 0xFF),
      band(n1, 0xFF),
      band(n2, 0xFF),
      band(n3, 0xFF),
      band(n4, 0xFF)
    ]
  end

  def build(header, name, key, val, options) do
    [header, key, ?:, val,  ?|,  metric_type(name)]
    |> set_option(:sample_rate,options[:sample_rate])
    |> set_option(:tags,options[:tags])
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
  defp set_option(stats, _, nil), do: stats
  defp set_option(stats, :sample_rate,sample_rate) do
    [stats | ["|@", :io_lib.format('~.2f', [sample_rate])]]
  end
  defp set_option(stats, :tags, tags) do
    [stats | ["|#", Enum.join(tags,",") ]]
  end
end
