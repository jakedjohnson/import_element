defmodule ImportElement.MethodApi.Client do
  @moduledoc """
  HTTPoison wrapper for the Method API client interface
  """
  use HTTPoison.Base

  @expected_fields ~w(
    data message success
  )

  def process_request_url(url) do
    Application.fetch_env(:import_element, :method_url) <> url
  end

  def process_request_headers(headers \\ []) do
    {:ok, api_key} = Application.fetch_env(:import_element, :method_api_key)
    headers ++ [Authorization: "Bearer #{api_key}"]
  end

  def process_response_body(body) do
    body
    |> Poison.decode!()
    |> Map.take(@expected_fields)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
