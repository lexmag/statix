defmodule Statix.Packet do
  use Bitwise

  def header({n1, n2, n3, n4}, port) do
    [band(bsr(port, 8), 0xFF),
     band(port, 0xFF),
     band(n1, 0xFF),
     band(n2, 0xFF),
     band(n3, 0xFF),
     band(n4, 0xFF)]
  end

  def build(header, name, key, val) do
    [header, key, ?:, val, ?| | metric_type(name)]
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
end
