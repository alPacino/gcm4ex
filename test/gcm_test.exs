defmodule GCMTest do
  use ExUnit.Case

  test "GCM starts all the pools from config" do
    for {pool, _conf} <- Application.get_env(:gcm, :pools) do
      assert {:ready, _, _, _} = :poolboy.status(GCM.pool_name(pool))
    end
  end

  test "Payload can be built for any characters" do
    string = "test123 тест テスト !@#$%"
    msg =
      %GCM.Message{}
      |> Map.put(:token, String.duplicate("0", 64))
      |> Map.put(:notification, string)

    {:ok, result} = Poison.decode(GCM.Worker.build_payload(msg))
    assert result["notification"] == string
  end
end
