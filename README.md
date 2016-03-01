# GCM

The library was inspired by [apns4ex](https://github.com/chvanikoff/apns4ex)

## Warning

This library is a work in progress and it's API is subject to change till `v0.1`, please consider use of `== ver` operator rather than `~> ver` when requiring `gcm4ex` as a dependency or your application may be broken with next release of the library.

## Installation

  1. Add gcm to your list of dependencies in mix.exs:

        def deps do
          [{:gcm, "== 0.0.11"}]
        end

  2. Ensure gcm is started before your application:

        def application do
          [applications: [:gcm]]
        end

## Usage

Config the GCM app and define pools

```elixir
config :gcm,
  # Here goes "global" config applied as default to all pools started if not overwritten by pool-specific value
  callback_module:    GCM.Callback,
  timeout:            30,
  feedback_interval:  1200,
  reconnect_after:    1000,
  support_old_ios:    true,
  # Here are pools configs. Any value from "global" config can be overwritten in any single pool config
  pools: [
    # app1_dev_pool is the pool_name
    app1_dev_pool: [
      env: :dev,
      pool_size: 10,
      pool_max_overflow: 5,
      # and this is overwritten config key
      certfile: "/path/to/app1_dev.pem"
    ],
    app1_prod_pool: [
      env: :prod,
      certfile: "/path/to/app1_prod.pem",
      pool_size: 100,
      pool_max_overflow: 50
    ],
  ]
```

### Config keys

| Name              | Default value | Description                                                                                                                                                                                 |
|:------------------|:--------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cert              | nil           | Plaintext GCM certfile content (not needed if `certfile` is specified)                                                                                                                      |
| certfile          | nil           | Path to GCM certificate file or a tuple like `{:my_app, "certs/cert.pem"}` which will use a path relative to the `priv` folder of the given application (not needed if `cert` is specified) |
| cert_password     | nil           | GCM certificate password (if any)                                                                                                                                                           |
| key               | nil           | Plaintext GCM keyfile content (not needed if `keyfile` is specified)                                                                                                                        |
| keyfile           | nil           | Path to GCM keyfile (not needed if `key` is specified)                                                                                                                                      |
| callback_module   | GCM.Callback  | This module will receive all error and feedback messages from GCM                                                                                                                           |
| timeout           | 30            | Connection timeout in seconds                                                                                                                                                               |
| feedback_interval | 1200          | The app will check Apple feedback server every `feedback_interval` seconds                                                                                                                  |
| reconnect_after   | 1000          | Will reconnect after 1000 notifications sent                                                                                                                                                |
| support_old_ios   | true          | Push notifications are limited by 256 bytes (2kb if false), this option can be changed per message individually                                                                             |
| pools             | []            | List of pools to start                                                                                                                                                                      |

### Pool keys

| Pool key          | Description                                                                  |
|:------------------|:-----------------------------------------------------------------------------|
| env               | :dev for Apple sandbox push server or :prod for Apple production push server |
| pool_size         | Maximum pool size                                                            |
| pool_max_overflow | Maximum number of workers created if pool is empty                           |

All pools defined in config will be started automatically

From here and now you can start pushing your PNs via GCM.push/2 and GCM.push/3:
```Elixir
message = GCM.Message.new
message = message
|> Map.put(:token, "0000000000000000000000000000000000000000000000000000000000000000")
|> Map.put(:notification, "Hello world!")
|> Map.put(:badge, 42)
|> Map.put(:data, %{
  "var1" => "val1",
  "var2" => "val2"
})
GCM.push :app1_dev_pool, message
```
or
```Elixir
GCM.push :app1_prod_pool, "0000000000000000000000000000000000000000000000000000000000000000", "Hello world!"
```

## Handling GCM errors and feedback

You can define callback handler module via config param `callback_module`, the module should implement 2 functions: `error/1` and `feedback/1`. These functions will be called when GCM responds with error or feedback to the app. `%GCM.Error` and `%GCM.Feedback` structs are passed to the functions accordingly.

## Structs

- %GCM.Message{}
```elixir
defstruct [
  id: nil,
  token: "",
  notification: "",
  data: []
]
```
- %GCM.Error{}
```elixir
defstruct [
  message_id: nil,
  status: nil,
  error: nil
]
```
- %GCM.Feedback{}
```elixir
defstruct [
  time: nil,
  token: nil
]
```
- %GCM.Message.Loc{}
```elixir
defstruct [
  title: "",
  body: "",
  title_loc_key: nil,
  title_loc_args: nil,
  action_loc_key: nil,
  body_loc_key: "",
  body_loc_args: [],
  launch_image: nil
]
```
