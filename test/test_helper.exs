ExUnit.start()

defmodule GCM.TestHelper do
  require ExUnit.Assertions
  import ExUnit.Assertions

  defmodule FakeHttpBase do
    def post(_url, body, headers, status_code \\ 200)
    def post(_url, body, headers, status_code) when is_number(status_code) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: headers}}
    end
    def post(url, body, headers, server_body) when is_map(body) do
      body = body |> Map.merge(server_body) |> Poison.encode!()
      FakeHttpBase.post(url, body, headers)
    end
    def post(url, body, headers, %{results: results} = server_body) do
      body = Poison.decode!(body)

      results = if body["registration_ids"] do
        body["registration_ids"]
        |> Stream.with_index
        |> Enum.map(fn ({registration_id, index}) ->
          %{error: Enum.at(results, index)["error"], registration_id: registration_id}
        end)
      else
        [%{error: Enum.at(results, 0)["error"], registration_id: body["to"]}]
      end

      body = body |> Map.merge(%{results: results})
      FakeHttpBase.post(url, body, headers, server_body)
    end
    def post(url, body, headers, server_body) do
      body = Poison.decode!(body)
      FakeHttpBase.post(url, body, headers, server_body)
    end
  end

  def assert_push(real, expected) do
    real = Enum.map real, fn ({:ok, r}) ->
      body = Poison.decode!(r.body)
      r = Map.put(r, :body, Map.delete(body, "results"))
      {:ok, r}
    end
    expected = Enum.map expected, fn (r) ->
      {:ok, r}
    end

    assert real == expected
  end

  def expected_push_response(attributes) do
    headers = [
      {"Authorization", "key=api_key"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    res = %{
      body: %{
        "registration_ids" => attributes[:registration_ids],
        "data" => %{"alert" => "Push!"},
        "failure" => attributes[:failure] || 0,
        "success" => attributes[:success] || 0
      },
      failure: attributes[:failure] || 0,
      success: attributes[:success] || 0,
      canonical_ids: attributes[:canonical_ids] || [],
      headers: headers,
      invalid_registration_ids: attributes[:invalid_registration_ids] || [],
      not_registered_ids: attributes[:not_registered_ids] || [],
      deletable_registration_ids: attributes[:deletable_registration_ids] || [],
      status_code: 200
    }

    if attributes[:canonical_ids] do
      res = put_in(res, [:body, "canonical_ids"], length(attributes[:canonical_ids]))
    end

    if attributes[:to] do
      res = Map.put(res, :body, Map.delete(res.body, "registration_ids"))
      res = put_in(res, [:body, "to"], attributes[:to])
    end

    res
  end
end
