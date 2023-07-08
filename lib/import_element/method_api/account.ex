defmodule ImportElement.MethodApi.Account do
  def create(client.account_params) do
    {:ok, response} =
      client.post(
        "/accounts",
        Poison.encode!(account_params),
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end
end
