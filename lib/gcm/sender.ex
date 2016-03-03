# Stolen from https://github.com/carnivalmobile/gcm

defmodule GCM.Sender do
  alias HTTPoison.Response
  require Logger

  @base_url "https://gcm-http.googleapis.com/gcm"
  @empty_results %{not_registered_ids: [], canonical_ids: [], invalid_registration_ids: []}

  def push(api_key, registration_ids, options \\ %{}) do
    registration_ids = List.wrap(registration_ids)
    url = @base_url <> "/send"
    body = case registration_ids do
      [id] -> %{to: id}
      ids -> %{registration_ids: ids}
    end |> Dict.merge(options) |> Poison.encode!

    Logger.info(["POST", url, "\nbody:", inspect(body), "\nheaders:", inspect(headers(api_key))])

    case HTTPoison.post(url, body, headers(api_key)) do
      {:ok, response} -> build_response(registration_ids, response)
      error -> error
    end
  end

  defp build_response(_, %Response{status_code: 400}), do: {:error, :bad_request}
  defp build_response(_, %Response{status_code: 401}), do: {:error, :unauthorized}
  defp build_response(_, %Response{status_code: 503}), do: {:error, :service_unavailable}
  defp build_response(_, %Response{status_code: code}) when code in 500..599, do: {:error, :server_error}
  defp build_response(registration_ids, %Response{headers: headers, status_code: 200, body: body}) do
    response = Poison.decode!(body)
    results = build_results(response, registration_ids)
    defaults = %{
      failure: response["failure"],
      success: response["success"],
      body: body,
      headers: headers,
      status_code: 200
    }

    {:ok, Map.merge(results, defaults)}
  end

  defp build_results(%{"failure" => 0, "canonical_ids" => 0}, _), do: @empty_results
  defp build_results(%{"results" => results}, reg_ids) do
    response = @empty_results

    Enum.zip(reg_ids, results)
    |> Enum.reduce response, fn({reg_id, result}, response) ->
      case result do
        %{"error" => "NotRegistered"} ->
          update_in(response[:not_registered_ids], &([reg_id | &1]))
        %{"error" => "InvalidRegistration"} ->
          update_in(response[:invalid_registration_ids], &([reg_id | &1]))
        %{"registration_id" => new_reg_id} ->
          update = %{old: reg_id, new: new_reg_id}
          update_in(response[:canonical_ids], &([update | &1]))
        _ -> response
      end
    end
  end
  defp build_results(_, _), do: @empty_results

  defp headers(api_key) do
    [{ "Authorization", "key=#{api_key}" },
     { "Content-Type", "application/json" },
     { "Accept", "application/json"}]
  end
end
