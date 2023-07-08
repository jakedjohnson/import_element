defmodule ImportElement.MethodApi.Entity do
  def create(client, entity_params) do
    {:ok, response} =
      client.post(
        "/entities",
        Poison.encode!(entity_params),
        [{"Content-Type", "application/json"}]
      )

    response.body[:data]
  end
end
