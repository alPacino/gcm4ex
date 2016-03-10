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

TODO: add callback module support to handle GCM feedback.

### Config keys

| Name       | Default value | Description                                                     |
|:-----------|:--------------|:----------------------------------------------------------------|
| pools      | []            | List of pools to start                                          |
| batch_size | 1000          | Number of registration ids to send with each multicast request* |

* Google do not allow more than 1000 registration ids to be sent in the same request!

### Pool keys

| Pool key          | Description                                        |
|:------------------|:---------------------------------------------------|
| key               | GCM API key                                        |
| pool_size         | Maximum pool size                                  |
| pool_max_overflow | Maximum number of workers created if pool is empty |

All pools defined in config will be started automatically

From here and now you can start pushing your PNs via GCM.push/2 and GCM.push/3

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

### Send un-supervised one-off push messages

The supervised, pooled `GCM.push\2` is probably what you want to use in your app
but if you just want to play around with push messages from the console it can be
convenient to use the bare `GCM.Sender.push` function:

A successful push looks like this:

```
iex> GCM.Sender.push("api_key", ["registration_id1", "registration_id2"], %{notification: %{title: "Hello!"}})
{:ok, %{
  status_code: 200,
  success: 2,
  failure: 0,
  body: "{}",
  canonical_ids: [],
  headers: [{"Content-Type", "application/json; charset=UTF-8"}, …],
  invalid_registration_ids: [],
  not_registered_ids: []
}}
```

A successful push may have a list of `canonical_ids` which means that you **should** update your registration id to the `new` one.

```
iex> GCM.Sender.push(api_key, ["registration_id1", "registration_id2"])
{:ok, %{
  status_code: 200,
  success: 2,
  failure: 0,
  body: "{}",
  canonical_ids: [%{old: "registration_id1", new: "new_registration_id1"}],
  headers: […],
  invalid_registration_ids: [],
  not_registered_ids: []
}}
```

A partial successful push may have `not_registered_ids` and/or `invalid_registration_ids`.
A "not registered id" is a registration id that was valid. According to GCM: "An existing registration token may cease to be valid in a number of scenarios..."

An invalid registration is just wrong data.

```
iex> GCM.Sender.push(api_key, ["registration_id1", "registration_id2", "registration_id3"])
{:ok, %{
  status_code: 200,
  success: 1,
  failure: 2,
  body: "{}",
  canonical_ids: [],
  headers: […],
  invalid_registration_ids: ["registration_id2"],
  not_registered_ids: ["registration_id1"]
}}
```

If the push failed the return is `{:error, reason}` where reason will include more information on what failed.

More info here: https://developers.google.com/cloud-messaging/http
