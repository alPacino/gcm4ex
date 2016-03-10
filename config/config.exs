use Mix.Config

config :logger,
  backends: [:console],
  level: :info

config :gcm,
  batch_size: 1000,
  success_callback_module: GCM.Callbacks.SuccessHandler,
  error_callback_module: GCM.Callbacks.ErrorHandler,
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

if Mix.env == :test do
  import_config "test.exs"
end
