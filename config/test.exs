use Mix.Config

config :logger, backends: [], level: :debug
config :ex_unit, capture_log: true
config :gcm, batch_size: 3
