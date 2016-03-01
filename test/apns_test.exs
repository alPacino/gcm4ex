defmodule GCMTest do
  use ExUnit.Case
  require Logger
  doctest GCM

  @payload_min_size 38

  test "GCM starts all the pools from config" do
    for {pool, _conf} <- Application.get_env(:gcm, :pools) do
      assert {:ready, _, _, _} = :poolboy.status(GCM.pool_name(pool))
    end
  end

  test "If PN exceeds length of 256 bytes, it still builds proper payload by truncating notification message" do
    msg = %GCM.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:notification, String.duplicate("lorem ipsum", 100))
    payload = GCM.Worker.build_payload(msg, 256)
    assert byte_size(payload) == 256
    assert payload =~ "…"
  end

  test "PN with UTF8-characters is properly truncated" do
    msg = %GCM.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:notification, String.duplicate("ありがとう", 30))
    payload = GCM.Worker.build_payload(msg, 256)
    # When truncating UTF8 chars, payload size may be less than 256
    assert byte_size(payload) <= 256
    assert payload =~ "…"
  end

  test "If PN length is less than 256, it is not truncated" do
    string = "lorem ipsum"
    msg = %GCM.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:notification, string)
    payload = GCM.Worker.build_payload(msg, 256)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end

  test "Ellipsis absent when message size is exactly 256 bytes" do
    string = String.duplicate("a", 256 - @payload_min_size)
    msg = %GCM.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:notification, string)
    payload = GCM.Worker.build_payload(msg, 256)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end

  test "Payload can be built for any characters" do
    string = "test123 тест テスト !@#$%"
    msg = %GCM.Message{}
    |> Map.put(:token, String.duplicate("0", 64))
    |> Map.put(:notification, string)
    payload = GCM.Worker.build_payload(msg, 256)
    assert byte_size(payload) == @payload_min_size + byte_size(string)
    refute payload =~ "…"
  end
end
