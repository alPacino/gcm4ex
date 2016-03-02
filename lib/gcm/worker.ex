defmodule GCM.Worker do
  use GenServer
  require Logger

  def start_link(pool_conf) do
    GenServer.start_link(__MODULE__, pool_conf, [])
  end

  def init(pool_conf) do
    config = get_config(pool_conf)
    log(["Init GCM.Worker", config], :debug)

    {:ok, %{config: config, counter: 0}}
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
    key = Dict.fetch!(config, :key)
    host = Dict.fetch!(config, :host)

    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"Authorization", "key=" <> key}
    ]

    log(["POST", host, "\nbody:", payload, "\nheaders:", headers])
    HTTPoison.post!(host, payload, headers)
  end

  defp get_config(pool_conf) do
    Application.get_all_env(:gcm) ++ [
      host: "https://gcm-http.googleapis.com/gcm",
      key: pool_conf[:key]
    ]
  end

  defp log(parts, level \\ :info) do
    parts = Enum.map parts, fn(part) ->
      if is_binary(part) do
        part
      else
        inspect(part)
      end
    end

    Logger.log(level, Enum.join(parts, " "))
  end
end
