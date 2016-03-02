defmodule GCM.Worker do
  use GenServer
  require Logger

  def start_link(pool_conf) do
    config = Application.get_all_env(:gcm) ++ [key: pool_conf[:key]]
    state = %{counter: 0, config: config}

    Logger.debug(["Init GCM.Worker", inspect(state)])
    GenServer.start_link(__MODULE__, state, [])
  end

  def handle_call(%GCM.Message{token: registration_id} = message, _from, %{config: config, counter: counter} = state) do
    send_message(config, registration_id, message)
    {:reply, :ok, %{state | counter: counter + 1}}
  end

  defp send_message(config, registration_ids, message) do
    api_key = Dict.fetch!(config, :key)
    GCM.Sender.push(api_key, registration_ids, Map.delete(message, :__struct__))
  end
end
