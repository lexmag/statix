defmodule StatixTest do
  use ExUnit.Case

  defmodule Server do
    def start(test, port) do
      {:ok, sock} = :gen_udp.open(port, [:binary, active: false])
      Task.start_link(fn ->
        recv(test, sock)
      end)
    end

    defp recv(test, sock) do
      send(test, {:server, recv(sock)})
      recv(test, sock)
    end

    defp recv(sock) do
      case :gen_udp.recv(sock, 0) do
        {:ok, {_, _, packet}} ->
          packet
        {:error, _} = error ->
          error
      end
    end
  end

  defmodule Sample do
    use Statix
  end

  setup do
    {:ok, _} = Server.start(self(), 8125)
    Sample.connect
  end

  test "increment/1,2,3" do
    Sample.increment("sample")
    assert_receive {:server, "sample:1|c"}

    Sample.increment(["sample"], 2)
    assert_receive {:server, "sample:2|c"}

    Sample.increment("sample", 2.1)
    assert_receive {:server, "sample:2.1|c"}

    Sample.increment("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|c|#foo:bar,baz"}

    refute_received _any
  end

  test "decrement/1,2,3" do
    Sample.decrement("sample")
    assert_receive {:server, "sample:-1|c"}

    Sample.decrement(["sample"], 2)
    assert_receive {:server, "sample:-2|c"}

    Sample.decrement("sample", 2.1)
    assert_receive {:server, "sample:-2.1|c"}

    Sample.decrement("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:-3|c|#foo:bar,baz"}

    refute_received _any
  end

  test "gauge/2,3" do
    Sample.gauge(["sample"], 2)
    assert_receive {:server, "sample:2|g"}

    Sample.gauge("sample", 2.1)
    assert_receive {:server, "sample:2.1|g"}

    Sample.gauge("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|g|#foo:bar,baz"}

    refute_received _any
  end

  test "histogram/2,3" do
    Sample.histogram("sample", 2)
    assert_receive {:server, "sample:2|h"}

    Sample.histogram("sample", 2.1)
    assert_receive {:server, "sample:2.1|h"}

    Sample.histogram("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|h|#foo:bar,baz"}

    refute_received _any
  end

  test "timing/2,3" do
    Sample.timing(["sample"], 2)
    assert_receive {:server, "sample:2|ms"}

    Sample.timing("sample", 2.1)
    assert_receive {:server, "sample:2.1|ms"}

    Sample.timing("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|ms|#foo:bar,baz"}

    refute_received _any
  end

  test "measure/2" do
    expected_result = "the stuff."
    fun_result = Sample.measure(["sample"], fn ->
      :timer.sleep(100)
      expected_result
    end)
    assert_receive {:server, <<"sample:10", _, "|ms">>}
    assert fun_result == expected_result

    Sample.measure("sample", [tags: ["foo:bar", "baz"]], fn ->
      :timer.sleep(100)
    end)
    assert_receive {:server, <<"sample:10", _, "|ms|#foo:bar,baz">>}
  end

  test "set/2,3" do
    Sample.set(["sample"], 2)
    assert_receive {:server, "sample:2|s"}

    Sample.set("sample", 2.1)
    assert_receive {:server, "sample:2.1|s"}

    Sample.set("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|s|#foo:bar,baz"}

    refute_received _any
  end
end
