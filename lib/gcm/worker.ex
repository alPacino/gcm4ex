defmodule GCM.Worker do
  use GenServer
  require Logger

  def start_link(pool_conf) do
    GenServer.start_link(__MODULE__, pool_conf, [])
  end

  def init(pool_conf) do
    config = get_config(pool_conf)
    {:ok, %{config: config}}
  end

  def handle_call(%GCM.Message{} = message, _from, %{config: config} = state) do
    send_message(config, build_payload(message))

    {:reply, :ok, %{state | counter: state.counter + 1}}
  end

  def build_payload(message) do
    case Poison.encode(message) do
      {:ok, result} -> result
      {:error, error} -> Logger.error(error)
    end
  end

  defp send_message(config, payload) do
    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"Authorization", "key=" <> config.key}
    ]
    HTTPoison.post!(config.host, payload, headers)
  end

  defp get_config(pool_conf) do
    Application.get_all_env(:gcm) ++ [
      host: "https://gcm-http.googleapis.com/gcm", key: pool_conf[:key]
    ]
  end
end
