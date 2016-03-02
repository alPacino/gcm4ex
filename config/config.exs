use Mix.Config

config :logger,
  backends: [:console],
  level: :info

config :gcm,
  pools: [
    dev_pool: [
      env: :dev,
      key: "some_gcm_api_key",
      pool_size: 10,
      pool_max_overflow: 5
    ],
    prod_pool: [
      env: :prod,
      key: "some_gcm_api_key",
      pool_size: 100,
      pool_max_overflow: 50
    ]
  ]
