defmodule GCM.SenderTest do
  use ExUnit.Case
  import :meck
  alias GCM.Sender

  @moduletag :capture_log

  setup do
    on_exit fn -> unload end

    expected_headers = [
      {"Authorization", "key=api_key"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
    expected_response = %{
      canonical_ids: [],
      not_registered_ids: [],
      invalid_registration_ids: [],
      success: 0,
      failure: 0,
      status_code: 200,
      body: "original",
      headers: []
    }
    expected_http_response = %HTTPoison.Response{
      status_code: 200,
      body: "original",
      headers: []
    }
    expected_resp_body = %{
      "canonical_ids" => 0,
       "failure" => 0,
       "success" => 0,
       "results" => [%{"error" => "NotRegistered"}]
    }

    {:ok,
      expectations: %{
        headers: expected_headers,
        response: expected_response,
        http_response: expected_http_response,
        resp_body: expected_resp_body
      },
      options: %{data: %{alert: "Push!"}}
    }
  end

  test "push multicast notification to GCM with a 200 response", %{expectations: expectations, options: options} do
    registration_ids = ["reg1", "reg2"]
    resp_body = Map.put(expectations[:resp_body], "success", 2)
    expected_response = Map.put(expectations[:response], :success, 2)

    expect(Poison, :encode!, [%{registration_ids: registration_ids, data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, 1, resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", registration_ids, options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push unicast notification to GCM with a 200 response", %{expectations: expectations, options: options} do
    resp_body = Map.put(expectations[:resp_body], "success", 1)
    expected_response = Map.put(expectations[:response], :success, 1)

    expect(Poison, :encode!, [%{to: "reg1", data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, 1, resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", "reg1", options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with NotRegistered", %{expectations: expectations, options: options} do
    resp_body = Map.put(expectations[:resp_body], "failure", 1)
    expected_response =
      expectations[:response]
      |> Map.put(:failure, 1)
      |> Map.put(:not_registered_ids, ["reg1"])

    expect(Poison, :encode!, [%{to: "reg1", data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, ["original"], resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", "reg1", options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with InvalidRegistration", %{expectations: expectations, options: options} do
    resp_body =
      expectations[:resp_body]
      |> Map.put("failure", 1)
      |> Map.put("results", [%{"error" => "InvalidRegistration"}])
    expected_response =
      expectations[:response]
      |> Map.put(:failure, 1)
      |> Map.put(:invalid_registration_ids, ["reg1"])

    expect(Poison, :encode!, [%{to: "reg1", data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, ["original"], resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", "reg1", options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with canonical ids", %{expectations: expectations, options: options} do
    resp_body =
      expectations[:resp_body]
      |> Map.put("canonical_ids", 1)
      |> Map.put("success", 1)
      |> Map.put("results", [%{"registration_id" => "newreg1"}])
    expected_response =
      expectations[:response]
      |> Map.put(:success, 1)
      |> Map.put(:canonical_ids, [%{old: "reg1", new: "newreg1"}])

    expect(Poison, :encode!, [%{to: "reg1", data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, ["original"], resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", "reg1", options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with every supported result", %{expectations: expectations, options: options} do
    registration_ids = ["old_reg", "invalid_reg", "not_reg"]
    results = [
      %{"registration_id" => "new_reg"},
      %{"error" => "InvalidRegistration"},
      %{"error" => "NotRegistered"},
      %{"message_id" => "1:0408"}
    ]
    resp_body =
      expectations[:resp_body]
      |> Map.put("canonical_ids", 1)
      |> Map.put("success", 2)
      |> Map.put("failure", 2)
      |> Map.put("results", results)
    expected_response =
      expectations[:response]
      |> Map.put(:success, 2)
      |> Map.put(:failure, 2)
      |> Map.put(:not_registered_ids, ["not_reg"])
      |> Map.put(:invalid_registration_ids, ["invalid_reg"])
      |> Map.put(:canonical_ids, [%{old: "old_reg", new: "new_reg"}])

    expect(Poison, :encode!, [%{registration_ids: registration_ids, data: %{alert: "Push!"}}], "req_body")
    expect(Poison, :decode!, ["original"], resp_body)
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, expectations.http_response})

    assert Sender.push("api_key", registration_ids, options) == {:ok, expected_response}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 400 response", %{expectations: expectations} do
    registration_ids = ["reg1", "reg2"]
    http_response = %HTTPoison.Response{status_code: 400, body: "{}"}

    expect(Poison, :encode!, [%{registration_ids: registration_ids}], "req_body")
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, http_response})

    assert Sender.push("api_key", registration_ids) == {:error, :bad_request}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 401 response", %{expectations: expectations} do
    registration_ids = ["reg1", "reg2"]
    http_response = %HTTPoison.Response{status_code: 401, body: "{}"}

    expect(Poison, :encode!, [%{registration_ids: registration_ids}], "req_body")
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, http_response})

    assert Sender.push("api_key", registration_ids) == {:error, :unauthorized}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 503 response", %{expectations: expectations} do
    registration_ids = ["reg1", "reg2"]
    http_response = %HTTPoison.Response{status_code: 503, body: "{}"}

    expect(Poison, :encode!, [%{registration_ids: registration_ids}], "req_body")
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, http_response})

    assert Sender.push("api_key", registration_ids) == {:error, :service_unavailable}
    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 504 response", %{expectations: expectations} do
    registration_ids = ["reg1", "reg2"]
    http_response = %HTTPoison.Response{status_code: 504, body: "{}"}

    expect(Poison, :encode!, [%{registration_ids: registration_ids}], "req_body")
    expect(HTTPoison, :post, ["https://gcm-http.googleapis.com/gcm/send", "req_body", expectations.headers], {:ok, http_response})

    assert Sender.push("api_key", registration_ids) == {:error, :server_error}
    assert validate [Poison, HTTPoison]
  end
end
