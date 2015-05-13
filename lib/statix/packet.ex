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

  def build(header, type, key, val) do
    [header, key, ?:, val | metric(type)]
  end

  defp metric(:counter), do: '|c'
  defp metric(:gauge),   do: '|g'
  defp metric(:timing),  do: '|ms'
  defp metric(:set),     do: '|s'
end
