defmodule Statix.PoolingTest do
  use Statix.TestCase

  use Statix, runtime_config: true

  @pool_size 3

  setup do
    connect(pool_size: @pool_size)
  end

  test "starts :pool_size number of ports and randomly picks one" do
    uniq_count =
      [
        {:increment, [3]},
        {:decrement, [3]},
        {:gauge, [3]},
        {:histogram, [3]},
        {:timing, [3]},
        {:measure, [fn -> nil end]},
        {:set, [3]},
        {:distribution, [3]}
      ]
      |> Enum.map(fn {function, arguments} ->
        apply(__MODULE__, function, ["sample" | arguments])
      end)
      |> Enum.uniq_by(fn _ ->
        assert_receive {:test_server, %{port: port}, <<"sample:", _::bytes>>}
        port
      end)
      |> length()

    assert uniq_count in 2..@pool_size
  end
end
