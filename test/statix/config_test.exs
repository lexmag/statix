defmodule Statix.ConfigTest do
  use ExUnit.Case, async: false

  use Statix, runtime_config: true

  setup_all do
    {:ok, _} = Statix.TestServer.start_link(8125, __MODULE__.Server)
    :ok
  end

  setup do
    Statix.TestServer.setup(__MODULE__.Server)
  end

  test "global tags when present" do
    Application.put_env(:statix, :tags, ["tag:test"])

    connect()

    increment("sample", 3)
    assert_receive {:test_server, "sample:3|c|#tag:test"}

    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, "sample:3|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, :tags)
  end

  test "global connection-specific tags" do
    Application.put_env(:statix, __MODULE__, tags: ["tag:test"])

    connect()

    increment("sample", 3)
    assert_receive {:test_server, "sample:3|c|#tag:test"}

    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, "sample:3|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, __MODULE__)
  end
end
