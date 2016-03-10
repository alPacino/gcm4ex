defmodule GCM.SenderTest do
  use ExUnit.Case

  import GCM.TestHelper
  import GCM.TestHelper.FakeHttpBase

  alias GCM.Sender

  @moduletag :capture_log

  defmodule FakeHttpNoResult do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 0, success: 0})
    end
  end
  defmodule FakeHttp2Success do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 0, success: 2})
    end
  end
  defmodule FakeHttp1Success do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 0, success: 1})
    end
  end
  defmodule FakeHttp1FailureNotRegistered do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 1, success: 0, results: [%{"error" => "NotRegistered"}]})
    end
  end
  defmodule FakeHttp1FailureInvalidRegistration do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 1, success: 0, results: [%{"error" => "InvalidRegistration"}]})
    end
  end
  defmodule FakeHttp1SuccesCanonical do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 0, success: 1, canonical_ids: 1, results: [%{"registration_id" => "newreg1"}]})
    end
  end
  defmodule FakeHttpMixed do
    def post(url, body, headers) do
      post(url, body, headers, %{failure: 2, success: 2, canonical_ids: 1, results: [
        %{"registration_id" => "new_reg"},
        %{"error" => "InvalidRegistration"},
        %{"error" => "NotRegistered"},
        %{"message_id" => "1:0408"}
      ]})
    end
  end
  defmodule FakeHttp400 do
    def post(url, body, headers), do: post(url, body, headers, 400)
  end
  defmodule FakeHttp401 do
    def post(url, body, headers), do: post(url, body, headers, 401)
  end
  defmodule FakeHttp503 do
    def post(url, body, headers), do: post(url, body, headers, 503)
  end
  defmodule FakeHttp504 do
    def post(url, body, headers), do: post(url, body, headers, 504)
  end

  setup do
    {:ok, payload: %{data: %{alert: "Push!"}}}
  end

  test "push multicast notification to GCM with a 200 response", %{payload: payload} do
    response = expected_push_response(success: 2, registration_ids: ["reg1", "reg2"])
    assert_push(Sender.push("api_key", ["reg1", "reg2"], payload, FakeHttp2Success), [response])
  end

  test "push splits multicast into multiple requests of batch size", %{payload: payload} do
    response1 = expected_push_response(registration_ids: ["reg1", "reg2", "reg3"])
    response2 = expected_push_response(to: "reg4")
    assert_push(Sender.push("api_key", ["reg1", "reg2", "reg3", "reg4"], payload, FakeHttpNoResult), [response1, response2])
  end

  test "push unicast notification to GCM with a 200 response", %{payload: payload} do
    response = expected_push_response(success: 1, to: "reg1")
    assert_push(Sender.push("api_key", "reg1", payload, FakeHttp1Success), [response])
  end

  test "push notification to GCM with NotRegistered", %{payload: payload} do
    response = expected_push_response(failure: 1, to: "reg1", not_registered_ids: ["reg1"])
    assert_push(Sender.push("api_key", "reg1", payload, FakeHttp1FailureNotRegistered), [response])
  end

  test "push notification to GCM with InvalidRegistration", %{payload: payload} do
    response = expected_push_response(failure: 1, to: "reg1", invalid_registration_ids: ["reg1"])
    assert_push(Sender.push("api_key", "reg1", payload, FakeHttp1FailureInvalidRegistration), [response])
  end

  test "push notification to GCM with canonical ids", %{payload: payload} do
    response = expected_push_response(success: 1, to: "reg1", canonical_ids: [%{old: "reg1", new: "newreg1"}])
    assert_push(Sender.push("api_key", "reg1", payload, FakeHttp1SuccesCanonical), [response])
  end

  test "push notification to GCM with every supported result", %{payload: payload} do
    reg_ids = ["old_reg", "invalid_reg", "not_reg"]
    response = expected_push_response(
      registration_ids: reg_ids,
      success: 2,
      failure: 2,
      not_registered_ids: ["not_reg"],
      invalid_registration_ids: ["invalid_reg"],
      canonical_ids: [%{old: "old_reg", new: "new_reg"}]
    )
    assert_push(Sender.push("api_key", reg_ids, payload, FakeHttpMixed), [response])
  end

  test "push notification to GCM with a 400 response", %{payload: payload} do
    assert Sender.push("api_key", ["reg1"], payload, FakeHttp400) == [{:error, :bad_request}]
  end

  test "push notification to GCM with a 401 response", %{payload: payload} do
    assert Sender.push("api_key", ["reg1"], payload, FakeHttp401) == [{:error, :unauthorized}]
  end

  test "push notification to GCM with a 503 response", %{payload: payload} do
    assert Sender.push("api_key", ["reg1"], payload, FakeHttp503) == [{:error, :service_unavailable}]
  end

  test "push notification to GCM with a 504 response", %{payload: payload} do
    assert Sender.push("api_key", ["reg1"], payload, FakeHttp504) == [{:error, :server_error}]
  end
end
