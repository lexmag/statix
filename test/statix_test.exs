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
      if is_nil(test) or is_nil(current_test) do
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

  test "event/2,3" do
    # a generic Unix time
    now_unix = 1234

    StatixSample.event("sample title", "sample text")
    assert_receive {:server, "_e{12,11}:sample title|sample text"}

    StatixSample.event("sample title", "sample text", timestamp: now_unix)
    s = "_e{12,11}:sample title|sample text|d:#{now_unix}"
    assert_receive {:server, ^s}

    StatixSample.event("sample title", "sample text", hostname: "sample.hostname")
    assert_receive {:server, "_e{12,11}:sample title|sample text|h:sample.hostname"}

    StatixSample.event("sample title", "sample text", aggregation_key: "sample_aggregation_key")
    assert_receive {:server, "_e{12,11}:sample title|sample text|k:sample_aggregation_key"}

    StatixSample.event("sample title", "sample text", priority: :normal)
    assert_receive {:server, "_e{12,11}:sample title|sample text|p:normal"}

    StatixSample.event("sample title", "sample text", source_type_name: "sample source type")
    assert_receive {:server, "_e{12,11}:sample title|sample text|s:sample source type"}

    StatixSample.event("sample title", "sample text", alert_type: :warning)
    assert_receive {:server, "_e{12,11}:sample title|sample text|t:warning"}

    StatixSample.event("sample title", "sample text", tags: ["foo", "bar"])
    assert_receive {:server, "_e{12,11}:sample title|sample text|#foo,bar"}

    StatixSample.event("sample title", "sample text",
      timestamp: now_unix, hostname: "H", aggregation_key: "K",
      priority: :low, source_type_name: "S", alert_type: "T", tags: ["F", "B"])
    s = "_e{12,11}:sample title|sample text|d:#{now_unix}|h:H|k:K|p:low|s:S|t:T|#F,B"
    assert_receive {:server, ^s}

    refute_received _any
  end

  test "service_check/2,3" do
    # a generic Unix time
    now_unix = 1234

    StatixSample.service_check("sample name", :ok)
    assert_receive {:server, "_sc|sample name|0"}

    StatixSample.service_check("sample name", :ok, timestamp: now_unix)
    s = "_sc|sample name|0|d:#{now_unix}"
    assert_receive {:server, ^s}

    StatixSample.service_check("sample name", :ok, hostname: "sample.hostname")
    assert_receive {:server, "_sc|sample name|0|h:sample.hostname"}

    StatixSample.service_check("sample name", :ok, tags: ["foo", "bar"])
    assert_receive {:server, "_sc|sample name|0|#foo,bar"}

    StatixSample.service_check("sample name", :ok, message: "sample message")
    assert_receive {:server, "_sc|sample name|0|m:sample message"}

    StatixSample.service_check("sample name", :warning,
      timestamp: now_unix, hostname: "H", tags: ["F", "B"], message: "M")
    s = "_sc|sample name|1|d:#{now_unix}|h:H|#F,B|m:M"
    assert_receive {:server, ^s}

    refute_received _any
  end
end
