defmodule StatixTest do
  use ExUnit.Case

  defmodule Server do
    def start(test, port) do
      {:ok, sock} = :gen_udp.open(port, [:binary, active: false])
      Task.start_link fn ->
        recv(test, sock)
      end
    end

    defp recv(test, sock) do
      send(test, {:server, recv(sock)})
      recv(test, sock)
    end

    defp recv(sock) do
      case :gen_udp.recv(sock, 0) do
        {:ok, {_, _, packet}} -> packet
        {:error, _} = error -> error
      end
    end
  end

  defmodule Sample do
    use Statix
  end

  setup do
    {:ok, _} = Server.start(self(), 8125)
    Sample.connect()
  end

  test "increment/1,2" do
    Sample.increment("sample")

    assert_receive {:server, "sample:1|c"}

    Sample.increment("sample", 2)

    assert_receive {:server, "sample:2|c"}

    Sample.increment("sample", 2.1)

    assert_receive {:server, "sample:2.1|c"}

    refute_received _any
  end

  test "decrement/1,2" do
    Sample.decrement("sample")

    assert_receive {:server, "sample:-1|c"}

    Sample.decrement("sample", 2)

    assert_receive {:server, "sample:-2|c"}

    Sample.decrement("sample", 2.1)

    assert_receive {:server, "sample:-2.1|c"}

    refute_received _any
  end

  test "gauge/2" do
    Sample.gauge("sample", 2)

    assert_receive {:server, "sample:2|g"}

    Sample.gauge("sample", 2.1)

    assert_receive {:server, "sample:2.1|g"}

    refute_received _any
  end

  test "timing/2" do
    Sample.timing("sample", 2)

    assert_receive {:server, "sample:2|ms"}

    Sample.timing("sample", 2.1)

    assert_receive {:server, "sample:2.1|ms"}

    refute_received _any
  end

  test "set/2" do
    Sample.set("sample", 2)

    assert_receive {:server, "sample:2|s"}

    Sample.set("sample", 2.1)

    assert_receive {:server, "sample:2.1|s"}

    refute_received _any
  end
end
