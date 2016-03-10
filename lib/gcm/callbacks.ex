defmodule GCM.Callbacks.SuccessHandler do
  require Logger

  def handle(request: %{url: url, body: body, headers: headers}, response: response) do
    Logger.debug([
      "[GCM] success ",
      "\nPOST ", url,
      "\nheaders: ", inspect(headers),
      "\nto: ", inspect(body[:to]),
      "\ndata: ", inspect(body[:data]),
      "\nnotification: ", inspect(body[:notification]),
      "\nresponse: ", inspect(response)
    ])

    body[:registration_ids] |> List.wrap() |> Enum.each fn (id) ->
      Logger.debug(["[GCM] sent to ", id])
    end
  end
end

defmodule GCM.Callbacks.ErrorHandler do
  require Logger

  def handle(request: %{url: url, body: body, headers: headers}, reason: reason) do
    Logger.error([
      "[GCM] error ",
      "\nPOST ", url,
      "\nheaders: ", inspect(headers),
      "\nto: ", inspect(body[:to]),
      "\ndata: ", inspect(body[:data]),
      "\nnotification: ", inspect(body[:notification]),
      "\nreason: ", inspect(reason)
    ])

    body[:registration_ids] |> List.wrap() |> Enum.each fn (id) ->
      Logger.error(["[GCM] failed to send to ", id])
    end
  end
end
