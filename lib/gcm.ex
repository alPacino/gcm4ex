defmodule GCM do
  use Application

  def push(pool, token, notification) do
    msg =
      GCM.Message.new
      |> Map.put(:token, token)
      |> Map.put(:notification, notification)

    push(pool, msg)
  end

  def push(pool, %GCM.Message{} = msg) do
    :poolboy.transaction(pool_name(pool), fn(pid) ->
      GenServer.call(pid, msg)
    end)
  end

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: GCM.Supervisor]
    supervisor = Supervisor.start_link([], opts)

    pools = Application.get_env(:gcm, :pools)
    pools |> Enum.map(fn({name, conf}) -> connect_pool(name, conf) end)

    supervisor
  end

  def connect_pool(name, conf) do
    pool_args = [
      name: {:local, pool_name(name)},
      worker_module: GCM.Worker,
      size: conf[:pool_size],
      max_overflow: conf[:pool_max_overflow],
      strategy: :fifo
    ]
    child_spec = :poolboy.child_spec(pool_name(name), pool_args, conf)

    Supervisor.start_child(GCM.Supervisor, child_spec)
  end

  def pool_name(name) do
    "GCM.Pool.#{to_string(name)}" |> String.to_atom
  end
end
