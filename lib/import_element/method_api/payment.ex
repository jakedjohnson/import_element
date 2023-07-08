defmodule ImportElement.MethodApi.Payment do
  def create(client, payment_params) do
    {:ok, response} =
      client.post(
        "/payments",
        Poison.encode!(payment_params),
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end
end
