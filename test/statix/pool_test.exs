defmodule Statix.PoolTest do
  use Statix.TestCase

  use Statix, runtime_config: true

  @pool_size 10

  setup do
    connect()
  end

  setup_all do
    Application.put_env(:statix, :pool_size, @pool_size)

    on_exit(fn ->
      Application.delete_env(:statix, :pool_size)
    end)
  end

  test "starts `:pool_size` number of ports and randomly chooses one" do
    for _ <- 1..@pool_size do
      increment("pool")
    end

    ports =
      for _ <- 1..@pool_size do
        assert_receive {:test_server, %{port: port}, _}
        port
      end

    uniq_count = ports |> Enum.uniq() |> Enum.count()
    assert uniq_count > 1
  end

  test "increment/3" do
    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|c|#foo"}
  end

  test "decrement/3" do
    decrement("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:-3|c|#foo"}
  end

  test "gauge/3" do
    gauge("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|g|#foo"}
  end

  test "histogram/3" do
    histogram("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|h|#foo"}
  end

  test "timing/3" do
    timing("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|ms|#foo"}
  end

  test "measure/3" do
    measure("sample", [tags: ["foo"]], fn ->
      :timer.sleep(100)
    end)

    assert_receive {:test_server, _, <<"sample:10", _, "|ms|#foo">>}
  end

  test "set/3" do
    set("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|s|#foo"}
  end
end
