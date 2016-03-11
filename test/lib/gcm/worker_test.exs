defmodule GCM.WorkerTest do
  use ExUnit.Case

  setup do
    pool_conf = [key: "some_gcm_api_key", pool_size: 10, pool_max_overflow: 5]
    {:ok, pid} = GCM.Worker.start_link(pool_conf)
    {:ok, pid: pid}
  end

  test "worked handles call", %{pid: pid} do
    message = %GCM.Message{notification: %GCM.Message.Notification{body: "goal!"}}
    assert GenServer.call(pid, %{message: message, registration_ids: ["someregid"]}) == :ok
  end
end
