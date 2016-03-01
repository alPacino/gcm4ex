use Mix.Config

config :gcm,
  timeout: 30,
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
