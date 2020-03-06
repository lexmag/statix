defmodule Statix.ConfigTest do
  use Statix.TestCase, async: false

  use Statix, runtime_config: true

  test "connect/1" do
    connect(tags: ["tag:test"])

    increment("sample", 2)
    assert_receive {:test_server, _, "sample:2|c|#tag:test"}
  end

  test "global tags when present" do
    Application.put_env(:statix, :tags, ["tag:test"])

    connect()

    increment("sample", 3)
    assert_receive {:test_server, _, "sample:3|c|#tag:test"}

    increment("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, :tags)
  end

  test "global connection-specific tags" do
    Application.put_env(:statix, __MODULE__, tags: ["tag:test"])

    connect()

    increment("sample", 4)
    assert_receive {:test_server, _, "sample:4|c|#tag:test"}

    increment("sample", 4, tags: ["foo"])
    assert_receive {:test_server, _, "sample:4|c|#foo,tag:test"}
  after
    Application.delete_env(:statix, __MODULE__)
  end
end
