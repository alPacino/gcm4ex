# GCM

The library was inspired by [apns4ex](https://github.com/chvanikoff/apns4ex) and
much of the source code has been used as a bootstrap for this lib.

The HTTP wrapper has been heavily inspired by [carnivalmobile/gcm](https://github.com/carnivalmobile/gcm).

## Warning

This library is a work in progress and it's API is subject to change till `v0.1`, please consider use of `== ver` operator rather than `~> ver` when requiring `gcm4ex` as a dependency or your application may be broken with next release of the library.

## Installation

  1. Add gcm to your list of dependencies in mix.exs:

        def deps do
          [{:gcm, "== 0.0.1"}]
        end

  2. Ensure gcm is started before your application:

        def application do
          [applications: [:gcm]]
        end

## Usage

Config the GCM app and define pools

```elixir
config :gcm,
  # Here are pools configs. Any value from "global" config can be overwritten in any single pool config
  pools: [
    # app1_dev_pool is the pool_name
    app1_dev_pool: [
      env: :dev,
      pool_size: 10,
      pool_max_overflow: 5,
      # and this is overwritten config key
      key: "my gcm api key"
    ],
    app1_prod_pool: [
      env: :prod,
      key: "my gcm api key"
      pool_size: 100,
      pool_max_overflow: 50
    ],
  ]
```

### Config keys

| Name  | Default value | Description            |
|:------|:--------------|:-----------------------|
| pools | []            | List of pools to start |

### Pool keys

| Pool key          | Description                                                                  |
|:------------------|:-----------------------------------------------------------------------------|
| env               | :dev for Apple sandbox push server or :prod for Apple production push server |
| key               | GCM API key                                                                  |
| pool_size         | Maximum pool size                                                            |
| pool_max_overflow | Maximum number of workers created if pool is empty                           |

All pools defined in config will be started automatically

From here and now you can start pushing your PNs via GCM.push/2 and GCM.push/3

(TODO: Add usage here)
