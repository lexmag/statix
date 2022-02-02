defmodule Statix.ConfigTest do
  @server_port 8325

  use Statix.TestCase, async: false, port: @server_port

  use Statix, runtime_config: true

  test "connect/1" do
    connect(tags: ["tag:test"], prefix: "foo", port: @server_port)

    increment("sample", 2)
    assert_receive {:test_server, _, "foo.sample:2|c|#tag:test"}
  end

  test "global tags when present" do
    Application.put_env(:statix, :tags, ["tag:test"])

    connect(port: @server_port)

    increment("sample", 3)
    assert_receive {:test_server, _, "sample:3|c|#tag:test"}

    timing("sample", 3, tags: ["foo"])
    assert_receive {:test_server, _, "sample:3|ms|#foo,tag:test"}
  after
    Application.delete_env(:statix, :tags)
  end

  test "global connection-specific tags" do
    Application.put_env(:statix, __MODULE__, tags: ["tag:test"])

    connect(port: @server_port)

    set("sample", 4)
    assert_receive {:test_server, _, "sample:4|s|#tag:test"}

    gauge("sample", 4, tags: ["foo"])
    assert_receive {:test_server, _, "sample:4|g|#foo,tag:test"}
  after
    Application.delete_env(:statix, __MODULE__)
  end
end
