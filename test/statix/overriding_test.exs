defmodule Statix.OverridingTest do
  @server_port 8225

  use Statix.TestCase, port: @server_port

  Application.put_env(:statix, __MODULE__, port: @server_port)

  use Statix

  def increment(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def decrement(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def gauge(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def histogram(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def timing(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def measure(key, options, fun) do
    super([key, "-measure"], options, fun)
  end

  def set(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  def distribution(key, value, options) do
    super([key, "-overridden"], value, options)
  end

  setup do
    connect()
  end

  test "increment/3" do
    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|c|#foo"}
  end

  test "decrement/3" do
    decrement("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:-3|c|#foo"}
  end

  test "gauge/3" do
    gauge("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|g|#foo"}
  end

  test "histogram/3" do
    histogram("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|h|#foo"}
  end

  test "timing/3" do
    timing("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|ms|#foo"}
  end

  test "distribution/3" do
    distribution("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|d|#foo"}
  end

  test "measure/3" do
    measure("sample", [tags: ["foo"]], fn ->
      :timer.sleep(100)
    end)

    assert_receive {:test_server, _, <<"sample-measure-overridden:10", _, "|ms|#foo">>}
  end

  test "set/3" do
    set("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample-overridden:3|s|#foo"}
  end
end
