defmodule StatixTest do
  use ExUnit.Case

  defmodule Server do
    use GenServer

    def start_link(port) do
      GenServer.start_link(__MODULE__, port, name: __MODULE__)
    end

    def set_current_test(test) do
      GenServer.call(__MODULE__, {:set_current_test, test})
    end

    def init(port) do
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true])
      {:ok, %{socket: socket, test: nil}}
    end

    def handle_call({:set_current_test, current_test}, _from, %{test: test} = state) do
      if is_nil(test) do
        {:reply, :ok, %{state | test: current_test}}      
      else
        {:reply, :error, state}      
      end
    end

    def handle_info({:udp, socket, _, _, packet}, %{socket: socket, test: test} = state) do
      send(test, {:server, packet})
      {:noreply, state}
    end
  end

  runtime_config? = System.get_env("STATIX_TEST_RUNTIME_CONFIG") in ["1", "true"]
  content = quote do
    use Statix, runtime_config: unquote(runtime_config?)
  end
  Module.create(StatixSample, content, Macro.Env.location(__ENV__))

  setup_all do
    {:ok, _} = Server.start_link(8125)
    :ok
  end

  setup do
    :ok = Server.set_current_test(self())
    StatixSample.connect
    on_exit(fn -> Server.set_current_test(nil) end)
  end

  test "increment/1,2,3" do
    StatixSample.increment("sample")
    assert_receive {:server, "sample:1|c"}

    StatixSample.increment(["sample"], 2)
    assert_receive {:server, "sample:2|c"}

    StatixSample.increment("sample", 2.1)
    assert_receive {:server, "sample:2.1|c"}

    StatixSample.increment("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|c|#foo:bar,baz"}

    StatixSample.increment("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:server, "sample:3|c|@1.0|#foo,bar"}

    StatixSample.increment("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "decrement/1,2,3" do
    StatixSample.decrement("sample")
    assert_receive {:server, "sample:-1|c"}

    StatixSample.decrement(["sample"], 2)
    assert_receive {:server, "sample:-2|c"}

    StatixSample.decrement("sample", 2.1)
    assert_receive {:server, "sample:-2.1|c"}

    StatixSample.decrement("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:-3|c|#foo:bar,baz"}
    StatixSample.decrement("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])

    assert_receive {:server, "sample:-3|c|@1.0|#foo,bar"}

    StatixSample.decrement("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "gauge/2,3" do
    StatixSample.gauge(["sample"], 2)
    assert_receive {:server, "sample:2|g"}

    StatixSample.gauge("sample", 2.1)
    assert_receive {:server, "sample:2.1|g"}

    StatixSample.gauge("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|g|#foo:bar,baz"}

    StatixSample.gauge("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:server, "sample:3|g|@1.0|#foo,bar"}

    StatixSample.gauge("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "histogram/2,3" do
    StatixSample.histogram("sample", 2)
    assert_receive {:server, "sample:2|h"}

    StatixSample.histogram("sample", 2.1)
    assert_receive {:server, "sample:2.1|h"}

    StatixSample.histogram("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|h|#foo:bar,baz"}

    StatixSample.histogram("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:server, "sample:3|h|@1.0|#foo,bar"}

    StatixSample.histogram("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "timing/2,3" do
    StatixSample.timing(["sample"], 2)
    assert_receive {:server, "sample:2|ms"}

    StatixSample.timing("sample", 2.1)
    assert_receive {:server, "sample:2.1|ms"}

    StatixSample.timing("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|ms|#foo:bar,baz"}

    StatixSample.timing("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:server, "sample:3|ms|@1.0|#foo,bar"}

    StatixSample.timing("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "measure/2,3" do
    expected = "the stuff"
    result = StatixSample.measure(["sample"], fn ->
      :timer.sleep(100)
      expected
    end)
    assert_receive {:server, <<"sample:10", _, "|ms">>}
    assert result == expected

    StatixSample.measure("sample", [sample_rate: 1.0, tags: ["foo", "bar"]], fn ->
      :timer.sleep(100)
    end)
    assert_receive {:server, <<"sample:10", _, "|ms|@1.0|#foo,bar">>}

    refute_received _any
  end

  test "set/2,3" do
    StatixSample.set(["sample"], 2)
    assert_receive {:server, "sample:2|s"}

    StatixSample.set("sample", 2.1)
    assert_receive {:server, "sample:2.1|s"}

    StatixSample.set("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:server, "sample:3|s|#foo:bar,baz"}

    StatixSample.set("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:server, "sample:3|s|@1.0|#foo,bar"}

    StatixSample.set("sample", 3, sample_rate: 0.0)

    refute_received _any
  end
end
