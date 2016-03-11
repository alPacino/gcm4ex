# GCM

The library was inspired by [apns4ex](https://github.com/chvanikoff/apns4ex) and
much of the source code has been used as a bootstrap for this lib.

The HTTP wrapper has been heavily inspired by [carnivalmobile/gcm](https://github.com/carnivalmobile/gcm).

## Warning

This library is a work in progress and it's API is subject to change till `v0.1`, please consider use of `== ver` operator rather than `~> ver` when requiring `gcm4ex` as a dependency or your application may be broken with next release of the library.

## Installation

  1. Add gcm to your list of dependencies in mix.exs:

        def deps do
          [{:gcm, "== 0.0.2"}]
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
  success_callback_module: GCM.Callbacks.SuccessHandler,
  error_callback_module: GCM.Callbacks.ErrorHandler,
  batch_size: 1000,
  pools: [
    # app1_dev_pool is the pool_name
    app1_dev_pool: [
      pool_size: 10,
      pool_max_overflow: 5,
      # and this is overwritten config key
      key: "my gcm api key"
    ],
    app1_prod_pool: [
      key: "my gcm api key"
      pool_size: 100,
      pool_max_overflow: 50
    ],
  ]
```

### Config keys

| Name                    | Default value                | Description                                                      |
|:------------------------|:-----------------------------|:-----------------------------------------------------------------|
| success_callback_module | GCM.Callbacks.SuccessHandler | This module receive request and response data on success         |
| error_callback_module*  | GCM.Callbacks.ErrorHandler   | This module receive request and response data on error           |
| batch_size              | 1000                         | Number of registration ids to send with each multicast request** |
| pools                   | []                           | List of pools to start                                           |

\* Google do not allow more than 1000 registration ids to be sent in the same request!

### Pool keys

| Pool key          | Description                                        |
|:------------------|:---------------------------------------------------|
| key               | GCM API key                                        |
| pool_size         | Maximum pool size                                  |
| pool_max_overflow | Maximum number of workers created if pool is empty |

All pools defined in config will be started automatically

From here and now you can start pushing your PNs via GCM.push/2 and GCM.push/3

### Handle responses

The library comes with default callback modules that do logging. You might be
fine with the default `error_callback_module` but you'd want to write your own
`success_callback_module`. It need to handle the following response keys by updating
your database.

| Name                        | Action | Example                                      |
|:----------------------------|:-------|:---------------------------------------------|
| canonical_ids               | update | [%{old: "reg1", new: "newreg1"}]             |
| invalid_registration_ids    | delete | invalid_registration_ids: ["reg2"]           |
| not_registered_ids          | delete | not_registered_ids: ["reg3"]                 |
| deletable_registration_ids* | delete | deletable_registration_ids: ["reg2", "reg3"] |

\* `deletable_registration_ids` is a concatenation of `invalid_registration_ids` and `not_registered_ids`.
There should not be duplicates but it's not guaranteed by the lib. If you don't need
to distinguish between invalid and not registered ids you can ignore these keys and
only use `deletable_registration_ids`.


```elixir
[{:ok, %{
  status_code: 200,
  success: 2,
  failure: 0,
  body: "{}",
  canonical_ids: [],
  invalid_registration_ids: [],
  not_registered_ids: [],
  headers: [{"Content-Type", "application/json; charset=UTF-8"}, …]
}}, …]
```

See https://developers.google.com/cloud-messaging/http for more info

## Basic Usage

### Example using the notification payload:

```elixir
message =
  GCM.Message.new
  |> Map.put(:notification, %GCM.Message.Notification{title: "Hello world!"})
  |> Map.put(:data, %{"post_id" => "23"})

GCM.push(:app1_dev_pool, message)
```

### Example using the custom data structs:

```elixir
message = Map.put(GCM.Message.new, :data, %{"my-custom-key" => "Hello world!"})
GCM.push(:app1_dev_pool, message)
```

### Send un-supervised, one-off push messages

The supervised, pooled `GCM.push\2` is probably what you want to use in your app
but if you just want to play around with push messages from the console it can be
convenient to use the bare `GCM.Sender.push` function:

A successful push looks like this:

```
iex> GCM.Sender.push("api_key", ["registration_id1", "registration_id2"], %{notification: %{title: "Hello!"}})
```

If the push failed the return is `{:error, reason}` where reason will include more information on what failed.

More info here: https://developers.google.com/cloud-messaging/http
