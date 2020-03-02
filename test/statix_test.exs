runtime_config? = System.get_env("STATIX_TEST_RUNTIME_CONFIG") in ["1", "true"]

defmodule StatixTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  use Statix, runtime_config: unquote(runtime_config?)

  defp close_port() do
    %{conn: %Statix.Conn{sock: sock}} = current_statix()
    Port.close(sock)
  end

  setup_all do
    {:ok, _} = Statix.TestServer.start_link(8125, __MODULE__.Server)
    :ok
  end

  setup do
    Statix.TestServer.setup(__MODULE__.Server)
    connect()
  end

  test "increment/1,2,3" do
    __MODULE__.increment("sample")
    assert_receive {:test_server, "sample:1|c"}

    increment(["sample"], 2)
    assert_receive {:test_server, "sample:2|c"}

    increment("sample", 2.1)
    assert_receive {:test_server, "sample:2.1|c"}

    increment("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:3|c|#foo:bar,baz"}

    increment("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:test_server, "sample:3|c|@1.0|#foo,bar"}

    increment("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "decrement/1,2,3" do
    __MODULE__.decrement("sample")
    assert_receive {:test_server, "sample:-1|c"}

    decrement(["sample"], 2)
    assert_receive {:test_server, "sample:-2|c"}

    decrement("sample", 2.1)
    assert_receive {:test_server, "sample:-2.1|c"}

    decrement("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:-3|c|#foo:bar,baz"}
    decrement("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])

    assert_receive {:test_server, "sample:-3|c|@1.0|#foo,bar"}

    decrement("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "gauge/2,3" do
    __MODULE__.gauge(["sample"], 2)
    assert_receive {:test_server, "sample:2|g"}

    gauge("sample", 2.1)
    assert_receive {:test_server, "sample:2.1|g"}

    gauge("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:3|g|#foo:bar,baz"}

    gauge("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:test_server, "sample:3|g|@1.0|#foo,bar"}

    gauge("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "histogram/2,3" do
    __MODULE__.histogram("sample", 2)
    assert_receive {:test_server, "sample:2|h"}

    histogram("sample", 2.1)
    assert_receive {:test_server, "sample:2.1|h"}

    histogram("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:3|h|#foo:bar,baz"}

    histogram("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:test_server, "sample:3|h|@1.0|#foo,bar"}

    histogram("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "timing/2,3" do
    __MODULE__.timing(["sample"], 2)
    assert_receive {:test_server, "sample:2|ms"}

    timing("sample", 2.1)
    assert_receive {:test_server, "sample:2.1|ms"}

    timing("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:3|ms|#foo:bar,baz"}

    timing("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:test_server, "sample:3|ms|@1.0|#foo,bar"}

    timing("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  test "measure/2,3" do
    expected = "the stuff"

    result =
      __MODULE__.measure(["sample"], fn ->
        :timer.sleep(100)
        expected
      end)

    assert_receive {:test_server, <<"sample:10", _, "|ms">>}
    assert result == expected

    measure("sample", [sample_rate: 1.0, tags: ["foo", "bar"]], fn ->
      :timer.sleep(100)
    end)

    assert_receive {:test_server, <<"sample:10", _, "|ms|@1.0|#foo,bar">>}

    refute_received _any
  end

  test "set/2,3" do
    __MODULE__.set(["sample"], 2)
    assert_receive {:test_server, "sample:2|s"}

    set("sample", 2.1)
    assert_receive {:test_server, "sample:2.1|s"}

    set("sample", 3, tags: ["foo:bar", "baz"])
    assert_receive {:test_server, "sample:3|s|#foo:bar,baz"}

    set("sample", 3, sample_rate: 1.0, tags: ["foo", "bar"])
    assert_receive {:test_server, "sample:3|s|@1.0|#foo,bar"}

    set("sample", 3, sample_rate: 0.0)

    refute_received _any
  end

  @tag :skip
  test "global tags when present" do
    Application.put_env(:statix, :tags, ["tag:test"])

    increment("sample", 3)
    assert_receive {:test_server, "sample:3|c|#tag:test"}

    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, "sample:3|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, :tags)
  end

  @tag :skip
  test "global connection-specific tags" do
    Application.put_env(:statix, __MODULE__, tags: ["tag:test"])

    increment("sample", 3)
    assert_receive {:test_server, "sample:3|c|#tag:test"}

    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, "sample:3|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, __MODULE__)
  end

  test "port closed" do
    close_port()

    assert capture_log(fn ->
             assert {:error, :port_closed} == increment("sample")
           end) =~ "counter metric \"sample\" lost value 1 due to port closure"

    assert capture_log(fn ->
             assert {:error, :port_closed} == decrement("sample")
           end) =~ "counter metric \"sample\" lost value -1 due to port closure"

    assert capture_log(fn ->
             assert {:error, :port_closed} == gauge("sample", 2)
           end) =~ "gauge metric \"sample\" lost value 2 due to port closure"

    assert capture_log(fn ->
             assert {:error, :port_closed} == histogram("sample", 3)
           end) =~ "histogram metric \"sample\" lost value 3 due to port closure"

    assert capture_log(fn ->
             assert {:error, :port_closed} == timing("sample", 2.5)
           end) =~ "timing metric \"sample\" lost value 2.5 due to port closure"
  end
end
